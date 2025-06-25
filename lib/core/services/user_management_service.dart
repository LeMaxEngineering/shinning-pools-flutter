import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserManagementService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Change user role (root only)
  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      if (kDebugMode) {
        debugPrint('UserManagementService: Attempting to change user role');
      }

      final callable = _functions.httpsCallable('changeUserRole');
      final result = await callable.call({
        'uid': userId,
        'newRole': newRole,
      });

      final data = result.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        if (kDebugMode) {
          debugPrint('UserManagementService: Role change successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('UserManagementService: Role change failed');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserManagementService: Error changing user role: $e');
      }
      rethrow;
    }
  }

  /// Get user information (root only)
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('UserManagementService: Getting user info');
      }

      final callable = _functions.httpsCallable('getUserInfo');
      final result = await callable.call({'uid': userId});

      final data = result.data as Map<String, dynamic>;
      return data['user'] as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserManagementService: Error getting user info: $e');
      }
      rethrow;
    }
  }

  /// List all users (root only)
  Future<List<Map<String, dynamic>>> listUsers() async {
    try {
      if (kDebugMode) {
        debugPrint('UserManagementService: Listing users');
      }

      final callable = _functions.httpsCallable('listUsers');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>? ?? [];

      return users.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserManagementService: Error listing users: $e');
      }
      rethrow;
    }
  }

  /// Check if current user is root
  Future<bool> isCurrentUserRoot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get user info to check role
      final userInfo = await getUserInfo(user.uid);
      if (userInfo == null) return false;

      final role = userInfo['role'] as String?;
      return role == 'root';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserManagementService: Error checking if user is root: $e');
      }
      return false;
    }
  }

  /// Get current user's role
  Future<String?> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userInfo = await getUserInfo(user.uid);
      return userInfo?['role'] as String?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserManagementService: Error getting current user role: $e');
      }
      return null;
    }
  }

  /// Validate role string
  bool isValidRole(String role) {
    const validRoles = ['root', 'admin', 'worker', 'customer'];
    return validRoles.contains(role.toLowerCase());
  }

  /// Get role display name
  String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'root':
        return 'Root Administrator';
      case 'admin':
        return 'Company Administrator';
      case 'worker':
        return 'Worker';
      case 'customer':
        return 'Customer';
      default:
        return role;
    }
  }
} 