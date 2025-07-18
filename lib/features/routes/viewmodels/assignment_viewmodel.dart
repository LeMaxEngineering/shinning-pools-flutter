import 'package:flutter/material.dart';
import '../services/assignment_service.dart';
import '../models/assignment.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/features/routes/services/assignment_service.dart';
import 'package:provider/provider.dart';
import '../../../core/services/user.dart';

class AssignmentViewModel extends ChangeNotifier {
  final AssignmentService _assignmentService;
  final AuthService _authService;

  AssignmentViewModel(this._authService, this._assignmentService) {
    _authService.addListener(_onAuthServiceChanged);
    // DO NOT initialize here. The UI will call it.
  }

  // State
  List<Assignment> _assignments = [];
  List<Assignment> _filteredAssignments = [];
  bool _isLoading = false;
  String? _error;
  String _statusFilter = 'All';
  String _dateFilter = 'All';
  bool _showHistorical = false;

  // Getters
  List<Assignment> get assignments => _assignments;
  List<Assignment> get filteredAssignments => _filteredAssignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get dateFilter => _dateFilter;
  bool get showHistorical => _showHistorical;

  @override
  void dispose() {
    _authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }

  void _onAuthServiceChanged() {
    // When auth state changes, schedule a reload after the current build cycle.
    Future.microtask(() => loadAssignments());
  }

  // Initialize
  Future<void> initialize() async {
    // This method is now called from the UI after the first frame.
    await loadAssignments();
  }

  // Load assignments
  Future<void> loadAssignments() async {
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _assignmentService.loadAssignments();
        _assignments = _assignmentService.assignments;
        _error = null;
      } else {
        _error = "User not logged in";
        _assignments = [];
      }
    } catch (e) {
      _error = e.toString();
      _assignments = [];
    } finally {
      _setLoading(false);
    }
  }

  // Create assignment
  Future<bool> createAssignment({
    required String routeId,
    required String workerId,
    required String notes,
    required String companyId,
    required DateTime routeDate,
    String? workerName,
    String? routeName,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _assignmentService.createAssignment(
        routeId: routeId,
        workerId: workerId,
        routeDate: routeDate,
        notes: notes,
        routeName: routeName,
        workerName: workerName,
      );

      if (success) {
        await loadAssignments(); // Reload assignments to get the new one
      } else {
        _error = _assignmentService.error ?? 'Failed to create assignment';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update assignment
  Future<bool> updateAssignment(String assignmentId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _error = null;

      // Extract the data and call the new updateAssignment method
      final routeId = data['routeId'] as String?;
      final workerId = data['workerId'] as String?;
      final routeDate = data['routeDate'] as DateTime?;
      final status = data['status'] as String?; // Add status extraction
      final notes = data['notes'] as String?;
      final routeName = data['routeName'] as String?;
      final workerName = data['workerName'] as String?;

      if (routeId == null || workerId == null || routeDate == null) {
        _error = 'Missing required fields for assignment update';
        _setLoading(false);
        return false;
      }

      final success = await _assignmentService.updateAssignment(
        assignmentId: assignmentId,
        routeId: routeId,
        workerId: workerId,
        routeDate: routeDate,
        status: status, // Add status to service call
        notes: notes,
        routeName: routeName,
        workerName: workerName,
      );

      if (success) {
        await loadAssignments(); // Reload assignments to get updated data
      } else {
        _error = _assignmentService.error ?? 'Failed to update assignment';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _assignmentService.deleteAssignment(assignmentId);

      if (success) {
        await loadAssignments(); // Reload assignments to remove the deleted one
      } else {
        _error = _assignmentService.error ?? 'Failed to delete assignment';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Complete assignment
  Future<bool> completeAssignment(String assignmentId, {String? result}) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _assignmentService.completeAssignment(assignmentId, result: result);

      if (success) {
        await loadAssignments(); // Reload assignments to get updated status
      } else {
        _error = _assignmentService.error ?? 'Failed to complete assignment';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Cancel assignment
  Future<bool> cancelAssignment(String assignmentId, {String? reason}) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _assignmentService.cancelAssignment(assignmentId, reason: reason);

      if (success) {
        await loadAssignments(); // Reload assignments to get updated status
      } else {
        _error = _assignmentService.error ?? 'Failed to cancel assignment';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Move to historical
  Future<bool> moveToHistorical(String assignmentId) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _assignmentService.moveToHistorical(assignmentId);

      if (success) {
        await loadAssignments(); // Reload assignments to get updated status
      } else {
        _error = _assignmentService.error ?? 'Failed to move assignment to historical';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Set status filter
  Future<void> setStatusFilter(String status) async {
    _statusFilter = status;
    await _applyFilters();
  }

  // Set date filter
  Future<void> setDateFilter(String dateFilter) async {
    _dateFilter = dateFilter;
    await _applyFilters();
  }

  Future<void> setHistoricalView(bool showHistorical) async {
    _showHistorical = showHistorical;
    await _applyFilters();
  }

  // Apply filters
  Future<void> _applyFilters() async {
    List<Assignment> baseList;
    if (_showHistorical) {
      baseList = await _assignmentService.getHistoricalAssignments();
    } else {
      baseList = _assignmentService.getActiveAssignments();
    }

    _filteredAssignments = baseList.where((assignment) {
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
    return _assignmentService.getAvailableStatuses();
  }

  List<String> getAvailableDateFilters() {
    return _assignmentService.getAvailableDateFilters();
  }

  Map<String, dynamic> getAssignmentStatistics() {
    return _assignmentService.getAssignmentStatistics();
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
    return _assignmentService.getStatusColor(status);
  }

  String formatDate(DateTime date) {
    return _assignmentService.formatDate(date);
  }

  String formatTime(DateTime time) {
    return _assignmentService.formatTime(time);
  }

  // Stream assignments for real-time updates
  Stream<List<Assignment>> streamAssignments() {
    return _assignmentService.streamAssignments();
  }

  // Check and expire routes
  Future<void> checkAndExpireRoutes() async {
    try {
      _setLoading(true);
      _error = null;
      
      await _assignmentService.checkAndExpireRoutes();
      
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Get current user
  AppUser? get currentUser => _authService.currentUser;
} 