import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';

class AssignmentValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService? _authService;

  AssignmentValidationService({AuthService? authService})
      : _authService = authService;

  /// Validates route assignment rules before creating or updating an assignment
  /// 
  /// Rules:
  /// 1. A route cannot be selected twice on the same day
  /// 2. A pool that belongs to a route cannot be in another route if both routes will be executed the same day
  /// 
  /// Returns a validation result with success status and error message if any
  Future<ValidationResult> validateAssignment({
    required String routeId,
    required DateTime routeDate,
    required String companyId,
    String? excludeAssignmentId, // For updates, exclude the current assignment
  }) async {
    try {
      // Rule 1: Check if the same route is already assigned on the same day
      final duplicateRouteResult = await _checkDuplicateRouteOnSameDay(
        routeId: routeId,
        routeDate: routeDate,
        companyId: companyId,
        excludeAssignmentId: excludeAssignmentId,
      );

      if (!duplicateRouteResult.isValid) {
        return duplicateRouteResult;
      }

      // Rule 2: Check for pool conflicts with other routes on the same day
      final poolConflictResult = await _checkPoolConflictsOnSameDay(
        routeId: routeId,
        routeDate: routeDate,
        companyId: companyId,
        excludeAssignmentId: excludeAssignmentId,
      );

      if (!poolConflictResult.isValid) {
        return poolConflictResult;
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Validation error: $e');
    }
  }

  /// Rule 1: Check if the same route is already assigned on the same day
  Future<ValidationResult> _checkDuplicateRouteOnSameDay({
    required String routeId,
    required DateTime routeDate,
    required String companyId,
    String? excludeAssignmentId,
  }) async {
    try {
      // Normalize the date to start of day for comparison
      final startOfDay = DateTime(routeDate.year, routeDate.month, routeDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query for existing assignments with the same route on the same day
      Query query = _firestore
          .collection('assignments')
          .where('companyId', isEqualTo: companyId)
          .where('routeId', isEqualTo: routeId)
          .where('routeDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('routeDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['Active', 'Hold']); // Only check active and hold assignments

      final snapshot = await query.get();

      // Filter out the current assignment if we're updating
      final conflictingAssignments = snapshot.docs.where((doc) {
        if (excludeAssignmentId != null && doc.id == excludeAssignmentId) {
          return false; // Exclude current assignment from conflict check
        }
        return true;
      }).toList();

      if (conflictingAssignments.isNotEmpty) {
        final conflictingAssignment = conflictingAssignments.first;
        final data = conflictingAssignment.data();
        final dataMap = data as Map<String, dynamic>?;
        final workerName = dataMap?['workerName'] ?? 'Unknown Worker';
        
        return ValidationResult.error(
          'Route is already assigned to $workerName on ${_formatDate(routeDate)}. '
          'A route cannot be selected twice on the same day.'
        );
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error checking duplicate routes: $e');
    }
  }

  /// Rule 2: Check for pool conflicts with other routes on the same day
  Future<ValidationResult> _checkPoolConflictsOnSameDay({
    required String routeId,
    required DateTime routeDate,
    required String companyId,
    String? excludeAssignmentId,
  }) async {
    try {
      // Get the pools in the current route
      final routeDoc = await _firestore.collection('routes').doc(routeId).get();
      if (!routeDoc.exists) {
        return ValidationResult.error('Route not found');
      }

      final routeData = routeDoc.data()!;
      final currentRoutePools = List<String>.from(routeData['stops'] ?? []);

      if (currentRoutePools.isEmpty) {
        return ValidationResult.success(); // No pools to check
      }

      // Normalize the date to start of day for comparison
      final startOfDay = DateTime(routeDate.year, routeDate.month, routeDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all assignments for the same day (excluding the current one if updating)
      Query assignmentsQuery = _firestore
          .collection('assignments')
          .where('companyId', isEqualTo: companyId)
          .where('routeDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('routeDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['Active', 'Hold']); // Only check active and hold assignments

      final assignmentsSnapshot = await assignmentsQuery.get();

      // Check each assignment for pool conflicts
      for (final assignmentDoc in assignmentsSnapshot.docs) {
        // Skip the current assignment if we're updating
        if (excludeAssignmentId != null && assignmentDoc.id == excludeAssignmentId) {
          continue;
        }

        final assignmentData = assignmentDoc.data();
        final assignmentDataMap = assignmentData as Map<String, dynamic>?;
        final otherRouteId = assignmentDataMap?['routeId'] as String?;
        
        if (otherRouteId == null || otherRouteId == routeId) {
          continue; // Skip if no route ID or if it's the same route
        }

        // Get the pools in the other route
        final otherRouteDoc = await _firestore.collection('routes').doc(otherRouteId).get();
        if (!otherRouteDoc.exists) {
          continue; // Skip if route doesn't exist
        }

        final otherRouteData = otherRouteDoc.data()!;
        final otherRoutePools = List<String>.from(otherRouteData['stops'] ?? []);

        // Check for overlapping pools
        final overlappingPools = currentRoutePools.where((pool) => otherRoutePools.contains(pool)).toList();

        if (overlappingPools.isNotEmpty) {
          final otherRouteName = otherRouteData['routeName'] ?? 'Unknown Route';
          final assignmentDataMap = assignmentData as Map<String, dynamic>?;
          final otherWorkerName = assignmentDataMap?['workerName'] ?? 'Unknown Worker';
          
          return ValidationResult.error(
            'Pool conflict detected! The following pools are already assigned to "$otherRouteName" '
            '($otherWorkerName) on ${_formatDate(routeDate)}: ${overlappingPools.join(', ')}. '
            'A pool cannot be in multiple routes on the same day.'
          );
        }
      }

      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.error('Error checking pool conflicts: $e');
    }
  }

  /// Helper method to format date for error messages
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Result class for validation operations
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  /// Create a successful validation result
  factory ValidationResult.success() {
    return ValidationResult._(isValid: true);
  }

  /// Create a failed validation result with error message
  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
} 