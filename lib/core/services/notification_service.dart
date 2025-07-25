import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification.dart';
import 'auth_service.dart';
import 'role.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Real-time listeners
  StreamSubscription? _notificationsListener;
  AppNotification? _latestNotification;

  // Notification preferences
  Map<String, bool> _preferences = {};
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  NotificationService(this._authService);

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppNotification? get latestNotification => _latestNotification;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  Map<String, bool> get preferences => _preferences;

  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get notifications by priority
  List<AppNotification> getNotificationsByPriority(
    NotificationPriority priority,
  ) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  // Start listening for notifications
  void startListening() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('❌ No current user found - cannot start notification listener');
      return;
    }

    _notificationsListener?.cancel();

    print('🔔 Starting notification listener for user: ${currentUser.id}');
    print('🔔 User role: ${currentUser.role.name}');
    print('🔔 User companyId: ${currentUser.companyId}');
    print('🔔 User email: ${currentUser.email}');

    Query query = _firestore.collection('notifications');

    // Filter based on user role and company
    if (currentUser.role == UserRole.root) {
      // Root users see all notifications - no filter needed
      // The security rules will handle access control
      print('🔔 Root user - no query filter applied');
    } else if (currentUser.role == UserRole.admin) {
      // Admins see company notifications and their own
      if (currentUser.companyId == null || currentUser.companyId!.isEmpty) {
        print(
          '❌ Admin user has no companyId - this will cause permission issues',
        );
        _error = 'Admin user has no company ID assigned';
        notifyListeners();
        return;
      }
      // For admin users, we need to query for both company notifications and their own
      // Since Firestore doesn't support OR queries easily, we'll use a compound query
      query = query.where('companyId', isEqualTo: currentUser.companyId);
      print('🔔 Admin user - filtering by companyId: ${currentUser.companyId}');
    } else {
      // Workers and customers see only their own notifications
      query = query.where('recipientId', isEqualTo: currentUser.id);
      print(
        '🔔 Worker/Customer user - filtering by recipientId: ${currentUser.id}',
      );
    }

    print('🔔 Final query: ${query.toString()}');

    _notificationsListener = query
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit to last 100 notifications
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '🔔 Notification listener received ${snapshot.docChanges.length} changes',
            );

            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final notification = AppNotification.fromFirestore(change.doc);
                print('🔔 New notification: ${notification.title}');

                // Set as latest notification for real-time updates
                _latestNotification = notification;
                notifyListeners();

                // Show in-app notification if enabled
                _showInAppNotification(notification);
              }
            }

            // Update the full list
            _notifications = snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList();

            notifyListeners();
          },
          onError: (error) {
            print('❌ Error in notification listener: $error');
            print('❌ Error type: ${error.runtimeType}');
            print('❌ Error details: $error');

            // Check if it's a permission error
            if (error.toString().contains('permission-denied')) {
              print('❌ This is a permission denied error');
              print('❌ Current user role: ${currentUser.role.name}');
              print('❌ Current user companyId: ${currentUser.companyId}');
              print('❌ Current user ID: ${currentUser.id}');
            }

            _error = 'Error loading notifications: $error';
            notifyListeners();
          },
        );
  }

  // Stop listening for notifications
  void stopListening() {
    _notificationsListener?.cancel();
    _notificationsListener = null;
    _latestNotification = null;
  }

  // Create a new notification
  Future<String?> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
    required String recipientId,
    required String recipientRole,
    String? companyId,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionText,
  }) async {
    try {
      final notification = AppNotification(
        id: '', // Will be set by Firestore
        title: title,
        message: message,
        type: type,
        priority: priority,
        recipientId: recipientId,
        recipientRole: recipientRole,
        companyId: companyId,
        createdAt: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
        actionText: actionText,
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());

      print(
        '🔔 Created notification: ${notification.title} (ID: ${docRef.id})',
      );
      return docRef.id;
    } catch (e) {
      print('❌ Error creating notification: $e');
      _error = 'Error creating notification: $e';
      notifyListeners();
      return null;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications
          .where((n) => !n.isRead)
          .toList();

      for (final notification in unreadNotifications) {
        final docRef = _firestore
            .collection('notifications')
            .doc(notification.id);
        batch.update(docRef, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  // Clear latest notification (after showing in-app notification)
  void clearLatestNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  // Show in-app notification
  void _showInAppNotification(AppNotification notification) {
    // This will be implemented in Phase 2 with UI components
    print('🔔 In-app notification: ${notification.title}');
  }

  // Update notification preferences
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    _preferences = preferences;
    notifyListeners();

    // Save to local storage or Firestore
    // This will be implemented in Phase 3
  }

  // Toggle sound
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  // Toggle vibration
  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    notifyListeners();
  }

  // Create system notification (for root users)
  Future<String?> createSystemNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    return createNotification(
      title: title,
      message: message,
      type: NotificationType.system,
      priority: priority,
      recipientId: 'all',
      recipientRole: UserRole.root.name,
      data: data,
    );
  }

  // Create company notification (for admins and workers)
  Future<String?> createCompanyNotification({
    required String title,
    required String message,
    required String companyId,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
  }) async {
    return createNotification(
      title: title,
      message: message,
      type: type,
      priority: priority,
      recipientId: 'all',
      recipientRole: UserRole.admin.name,
      companyId: companyId,
      data: data,
    );
  }

  // Create user-specific notification
  Future<String?> createUserNotification({
    required String title,
    required String message,
    required String recipientId,
    required String recipientRole,
    String? companyId,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionText,
  }) async {
    return createNotification(
      title: title,
      message: message,
      type: type,
      priority: priority,
      recipientId: recipientId,
      recipientRole: recipientRole,
      companyId: companyId,
      data: data,
      actionUrl: actionUrl,
      actionText: actionText,
    );
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Test Firestore access
  Future<bool> testFirestoreAccess() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user for Firestore access test');
        return false;
      }

      print('🔍 Testing Firestore access for user: ${currentUser.id}');
      print('🔍 User role: ${currentUser.role.name}');
      print('🔍 User companyId: ${currentUser.companyId}');

      // Test basic collection access
      final testQuery = _firestore.collection('notifications').limit(1);
      final testSnapshot = await testQuery.get();

      print(
        '✅ Firestore access test successful - found ${testSnapshot.docs.length} documents',
      );
      return true;
    } catch (e) {
      print('❌ Firestore access test failed: $e');
      return false;
    }
  }

  // Create a test notification to verify permissions
  Future<String?> createTestNotification() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('❌ No current user for test notification');
        return null;
      }

      print('🔔 Creating test notification for user: ${currentUser.id}');

      final notificationId = await createUserNotification(
        title: 'Test Notification',
        message: 'This is a test notification to verify permissions',
        recipientId: currentUser.id,
        recipientRole: currentUser.role.name,
        companyId: currentUser.companyId,
        type: NotificationType.info,
        priority: NotificationPriority.medium,
      );

      if (notificationId != null) {
        print('✅ Test notification created successfully: $notificationId');
      } else {
        print('❌ Failed to create test notification');
      }

      return notificationId;
    } catch (e) {
      print('❌ Error creating test notification: $e');
      return null;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
