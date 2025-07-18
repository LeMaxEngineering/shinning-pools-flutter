import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment.dart';
import '../../../core/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'assignment_validation_service.dart';
import 'package:shinning_pools_flutter/core/services/firebase_auth_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AssignmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  AssignmentService({AuthService? authService})
      : _authService = authService ?? AuthService(FirebaseAuthRepository());

  // State
  List<Assignment> _assignments = [];
  List<Assignment> _filteredAssignments = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'All';
  String _dateFilter = 'All';

  // Getters
  List<Assignment> get assignments => _assignments;
  List<Assignment> get filteredAssignments => _filteredAssignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get dateFilter => _dateFilter;

  // Load assignments for current company
  Future<void> loadAssignments() async {
    try {
      _setLoading(true);
      _error = null;

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _error = 'User not authenticated';
        _setLoading(false);
        return;
      }

      final companyId = currentUser.companyId;
      if (companyId == null) {
        _error = 'User not associated with a company';
        _setLoading(false);
        return;
      }

      Query query = _firestore
          .collection('assignments')
          .where('companyId', isEqualTo: companyId);

      // If the user is a worker, they should only see their own assignments.
      if (currentUser.role == 'worker') {
        query = query.where('workerId', isEqualTo: currentUser.id);
      }
      
      final snapshot = await query.orderBy('routeDate', descending: true).get();

      _assignments = snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();

      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Stream assignments for real-time updates
  Stream<List<Assignment>> streamAssignments() {
    try {
      // First check if Firebase Auth has a current user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return Stream.error('User not authenticated - please log in again');
      }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
        // Try to load user data from Firestore directly
        return _firestore.collection('users').doc(firebaseUser.uid).get().asStream().asyncMap((userDoc) async {
          if (!userDoc.exists) {
            throw Exception('User profile not found in database');
          }
          
          final userData = userDoc.data() as Map<String, dynamic>;
          final companyId = userData['companyId'];
          
          if (companyId == null) {
            throw Exception('User not associated with a company - please contact administrator');
          }

          Query query = _firestore
              .collection('assignments')
              .where('companyId', isEqualTo: companyId);

          // If the user is a worker, they should only see their own assignments.
          if (userData['role'] == 'worker') {
            query = query.where('workerId', isEqualTo: firebaseUser.uid);
          }
          
          final snapshot = await query.orderBy('routeDate', descending: true).get();
          return snapshot.docs
            .map((doc) => Assignment.fromFirestore(doc))
            .toList();
        });
    }
    
    final companyId = currentUser.companyId;
    if (companyId == null) {
        return Stream.error('User not associated with a company - please contact administrator');
    }

    Query query = _firestore
        .collection('assignments')
        .where('companyId', isEqualTo: companyId);

    // If the user is a worker, they should only see their own assignments.
    if (currentUser.role == 'worker') {
      query = query.where('workerId', isEqualTo: currentUser.id);
    }
    
    return query.orderBy('routeDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
        .map((doc) => Assignment.fromFirestore(doc))
          .toList();
      }).handleError((error) {
        throw error;
    });
    } catch (e) {
      return Stream.error('Failed to load assignments: $e');
    }
  }

  // Create new assignment
  Future<bool> createAssignment({
    required String routeId,
    required String workerId,
    required DateTime routeDate,
    String? notes,
    String? routeName,
    String? workerName,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser?.companyId == null) {
        throw Exception('User not associated with a company');
      }

      // Validate assignment rules before creating
      final validationService = AssignmentValidationService(authService: _authService);
      final validationResult = await validationService.validateAssignment(
        routeId: routeId,
        routeDate: routeDate,
        companyId: currentUser!.companyId!,
      );

      if (!validationResult.isValid) {
        _error = validationResult.errorMessage;
        return false;
      }

      final assignment = Assignment(
        id: '', // Will be set by Firestore
        routeId: routeId,
        workerId: workerId,
        routeName: routeName,
        workerName: workerName,
        assignedAt: DateTime.now(),
        routeDate: routeDate,
        status: 'Active',
        companyId: currentUser.companyId!,
        notes: notes,
      );

      await _firestore.collection('assignments').add(assignment.toMap());
      return true;
    } catch (e) {
      print('Error creating assignment: $e');
      _error = e.toString();
      return false;
    }
  }

  // Update assignment
  Future<bool> updateAssignment({
    required String assignmentId,
    required String routeId,
    required String workerId,
    required DateTime routeDate,
    String? status, // Add status parameter
    String? notes,
    String? routeName,
    String? workerName,
  }) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore to get companyId
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data()!;
      final companyId = userData['companyId'] as String?;

      if (companyId == null) {
        throw Exception('User not associated with a company');
      }

      // Validate assignment rules before updating (exclude current assignment)
      // TODO: Re-enable after Firebase indexes are created
      /*
      final validationService = AssignmentValidationService(authService: _authService);
      final validationResult = await validationService.validateAssignment(
        routeId: routeId,
        routeDate: routeDate,
        companyId: companyId,
        excludeAssignmentId: assignmentId, // Exclude current assignment from validation
      );

      if (!validationResult.isValid) {
        _error = validationResult.errorMessage;
        return false;
      }
      */

      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'routeId': routeId,
        'workerId': workerId,
        'routeDate': Timestamp.fromDate(routeDate),
        'status': status, // Add status to update
        'notes': notes,
        'routeName': routeName,
        'workerName': workerName,
        'updatedAt': Timestamp.now(),
      });

      // Reload assignments to reflect the changes in the UI
      await loadAssignments();

      return true;
    } catch (e) {
      print('Error updating assignment: $e');
      _error = e.toString();
      return false;
    }
  }

  // Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      _setLoading(true);
      _error = null;

      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .delete();

      await loadAssignments();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Complete assignment
  Future<bool> completeAssignment(String assignmentId, {String? result}) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'status': 'Completed',
        'result': result ?? 'Successfully completed',
        'updatedAt': Timestamp.now(),
      });
      
      // Reload assignments to reflect the changes in the UI
      await loadAssignments();
      
      return true;
    } catch (e) {
      print('Error completing assignment: $e');
      return false;
    }
  }

  // Cancel assignment
  Future<bool> cancelAssignment(String assignmentId, {String? reason}) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'status': 'Cancelled',
        'result': reason ?? 'Assignment cancelled',
        'updatedAt': Timestamp.now(),
      });
      
      // Reload assignments to reflect the changes in the UI
      await loadAssignments();
      
      return true;
    } catch (e) {
      print('Error cancelling assignment: $e');
      return false;
    }
  }

  // Move to historical
  Future<bool> moveToHistorical(String assignmentId) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'status': 'Historical',
        'updatedAt': Timestamp.now(),
      });
      
      // Reload assignments to reflect the changes in the UI
      await loadAssignments();
      
      return true;
    } catch (e) {
      print('Error moving assignment to historical: $e');
      return false;
    }
  }

  // Check and expire routes when historical list is requested
  Future<void> checkAndExpireRoutes() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated for route expiration check');
        return;
      }

      // Call the Cloud Function to check and expire routes
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('checkAndExpireRoutes');
      
      final result = await callable.call();
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final expiredRoutes = data['expiredRoutes'] as int;
        final expiredAssignments = data['expiredAssignments'] as int;
        
        if (expiredRoutes > 0 || expiredAssignments > 0) {
          print('Expired $expiredRoutes routes and $expiredAssignments assignments');
          // Reload assignments to reflect the changes
          await loadAssignments();
        }
      }
    } catch (e) {
      print('Error checking and expiring routes: $e');    // Don't throw error to avoid breaking the UI
    }
  }

  // Get historical assignments
  Future<List<Assignment>> getHistoricalAssignments() async {
    // Check and expire routes before getting historical assignments
    await checkAndExpireRoutes();
    
    return _assignments.where((assignment) => assignment.isHistorical).toList();
  }

  // Get active assignments
  List<Assignment> getActiveAssignments() {
    return _assignments.where((assignment) => !assignment.isHistorical).toList();
  }

  // Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  // Set date filter
  void setDateFilter(String dateFilter) {
    _dateFilter = dateFilter;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredAssignments = _assignments.where((assignment) {
      // Status filter
      bool matchesStatus = _statusFilter == 'All' || 
                          assignment.status == _statusFilter ||
                          (_statusFilter == 'Historical' && assignment.isHistorical) ||
                          (_statusFilter == 'Active' && !assignment.isHistorical);

      // Date filter
      bool matchesDate = _dateFilter == 'All';
      if (_dateFilter != 'All' && assignment.routeDate != null) {
        final today = DateTime.now();
        final now = DateTime.now();
        final date = assignment.routeDate!;
        
        switch (_dateFilter) {
          case 'Today':
            matchesDate = date.year == today.year &&
                         date.month == today.month &&
                         date.day == today.day;
            break;
          case 'This Week':
            final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            matchesDate = date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                         date.isBefore(endOfWeek.add(const Duration(days: 1)));
            break;
          case 'This Month':
            matchesDate = date.year == now.year &&
                         date.month == now.month;
            break;
          default:
            matchesDate = true;
        }
      }

      return matchesStatus && matchesDate;
    }).toList();

    notifyListeners();
  }

  // Get assignment by ID
  Assignment? getAssignmentById(String assignmentId) {
    try {
      return _assignments.firstWhere((assignment) => assignment.id == assignmentId);
    } catch (e) {
      return null;
    }
  }

  // Get available statuses for filtering
  List<String> getAvailableStatuses() {
    return ['All', 'Active', 'Hold', 'Closed', 'Completed', 'Cancelled', 'Historical'];
  }

  List<String> getAvailableDateFilters() {
    return ['All', 'Today', 'This Week', 'This Month'];
  }

  Map<String, dynamic> getAssignmentStatistics() {
    final totalAssignments = _assignments.length;
    final activeAssignments = getActiveAssignments().length;
    final completedAssignments = _assignments.where((a) => a.status == 'Completed').length;
    final cancelledAssignments = _assignments.where((a) => a.status == 'Cancelled').length;
    final historicalAssignments = _assignments.where((a) => a.isHistorical).length;

    return {
      'total': totalAssignments,
      'active': activeAssignments,
      'completed': completedAssignments,
      'cancelled': cancelledAssignments,
      'historical': historicalAssignments,
      'completionRate': totalAssignments > 0 ? (completedAssignments / totalAssignments) : 0.0,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'hold':
        return Colors.yellow;
      case 'closed':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'historical':
        return Colors.grey;
      case 'no executed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> assignRouteToWorker(
      String routeId, String workerId, DateTime routeDate, {String? routeName, String? workerName}) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final companyId = currentUser.companyId;
      if (companyId == null) {
        throw Exception('User not associated with a company');
      }

      await _firestore.collection('assignments').add({
        'routeId': routeId,
        'workerId': workerId,
        'routeName': routeName,
        'workerName': workerName,
        'assignedAt': Timestamp.now(),
        'routeDate': Timestamp.fromDate(routeDate),
        'status': 'Active',
        'companyId': companyId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error assigning route: $e');
      rethrow;
    }
  }

  // Manually expire a specific route and its assignments
  Future<bool> manualExpireRoute(String routeId) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated for manual route expiration');
        return false;
      }

      // Call the Cloud Function to manually expire the route
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('manualExpireRoute');
      
      final result = await callable.call({'routeId': routeId});
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final expiredAssignments = data['expiredAssignments'] as int;
        print('Manually expired route $routeId with $expiredAssignments assignments');
        
        // Reload assignments to reflect the changes
        await loadAssignments();
        return true;
      } else {
        print('Failed to manually expire route: ${data['message']}');
        return false;
      }
    } catch (e) {
      print('Error manually expiring route: $e');
      return false;
    }
  }
} 