import 'package:flutter/material.dart';
import '../services/route_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route.dart';

class RouteViewModel extends ChangeNotifier {
  final RouteService _routeService;

  RouteViewModel({RouteService? routeService})
      : _routeService = routeService ?? RouteService();

  // State
  List<RouteModel> _routes = [];
  List<RouteModel> _filteredRoutes = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';
  String _workerFilter = 'All';

  // Getters
  List<RouteModel> get routes => _routes;
  List<RouteModel> get filteredRoutes => _filteredRoutes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  String get statusFilter => _statusFilter;
  String get workerFilter => _workerFilter;

  // Initialize
  Future<void> initialize() async {
    await loadRoutes();
  }

  // Load routes
  Future<void> loadRoutes() async {
    try {
      _setLoading(true);
      _error = null;

      final routeMaps = await _routeService.getRoutesForCompany();
      _routes = routeMaps.map((map) => RouteModel.fromFirestore(map)).toList();
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Create route
  Future<bool> createRoute({
    required String createdById,
    required DateTime date,
    required List<Map<String, dynamic>> stops,
    String status = 'pending',
    String? routeName,
    String? createdByName,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _routeService.createRoute(
        createdById: createdById,
        date: date,
        stops: stops,
        status: status,
        routeName: routeName,
        createdByName: createdByName,
      );

      if (success) {
        await loadRoutes(); // Reload routes to get the new one
      } else {
        _error = _routeService.error ?? 'Failed to create route';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Start route
  Future<bool> startRoute(String routeId) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _routeService.startRoute(routeId);
      
      if (success) {
        await loadRoutes(); // Reload routes to get updated status
      } else {
        _error = _routeService.error ?? 'Failed to start route';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Complete route
  Future<bool> completeRoute(
    String routeId, {
    required double totalDistance,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _routeService.completeRoute(
        routeId,
        totalDistance: totalDistance,
        notes: notes,
      );

      if (success) {
        await loadRoutes(); // Reload routes to get updated status
      } else {
        _error = _routeService.error ?? 'Failed to complete route';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update stop status
  Future<bool> updateStopStatus(
    String routeId,
    int stopIndex,
    String status,
    Map<String, dynamic>? details,
  ) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _routeService.updateStopStatus(
        routeId,
        stopIndex,
        status,
        details,
      );

      if (success) {
        await loadRoutes(); // Reload routes to get updated status
      } else {
        _error = _routeService.error ?? 'Failed to update stop status';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Delete route
  Future<bool> deleteRoute(String routeId) async {
    try {
      _setLoading(true);
      _error = null;

      final success = await _routeService.deleteRoute(routeId);

      if (success) {
        await loadRoutes(); // Reload routes to remove the deleted one
      } else {
        _error = _routeService.error ?? 'Failed to delete route';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update route
  Future<bool> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _error = null;
      await _routeService.updateRoute(routeId, data);
      await loadRoutes(); // Refresh the list
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _applyFilters();
  }

  // Set status filter
  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  // Set worker filter
  void setWorkerFilter(String worker) {
    _workerFilter = worker;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredRoutes = _routes.where((route) {
      // Date filter
      DateTime? routeDate = route.createdAt;

      final matchesDate = routeDate.year == _selectedDate.year &&
                         routeDate.month == _selectedDate.month &&
                         routeDate.day == _selectedDate.day;

      // Status filter
      final matchesStatus = _statusFilter == 'All' ||
                           route.status.toLowerCase().replaceAll(' ', '_') == _statusFilter.toLowerCase().replaceAll(' ', '_');

      // Worker filter (assuming route has a workerId, if not this needs adjustment)
      // For now, let's assume no worker filter on route directly, can be adapted
      // final matchesWorker = _workerFilter == 'All' || route.workerId == _workerFilter;

      return matchesDate && matchesStatus; // && matchesWorker;
    }).toList();
    notifyListeners();
  }

  // Get available workers for filtering
  List<String> getAvailableWorkers() {
    // This is problematic as a route is not directly assigned to a worker.
    // This should probably be handled in the AssignmentViewModel
    // For now, returning a placeholder.
    return ['All'];
  }

  // Get available statuses for filtering
  List<String> getAvailableStatuses() {
    return ['All', 'Scheduled', 'In Progress', 'Completed', 'Cancelled'];
  }

  // Get route statistics
  Map<String, dynamic> getRouteStatistics() {
    final totalRoutes = _filteredRoutes.length;
    final completedRoutes = _filteredRoutes.where((route) => route.status == 'completed').length;
    final inProgressRoutes = _filteredRoutes.where((route) => route.status == 'in_progress').length;
    final pendingRoutes = _filteredRoutes.where((route) => route.status == 'pending').length;

    return {
      'totalRoutes': totalRoutes,
      'completedRoutes': completedRoutes,
      'inProgressRoutes': inProgressRoutes,
      'pendingRoutes': pendingRoutes,
      'completionRate': totalRoutes > 0 ? (completedRoutes / totalRoutes) : 0.0,
    };
  }

  // Get route by ID
  RouteModel? getRouteById(String routeId) {
    try {
      return _routes.firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Route status helpers
  String getRouteStatusDisplay(String status) {
    return _routeService.getRouteStatusDisplay(status);
  }

  Color getRouteStatusColor(String status) {
    return _routeService.getRouteStatusColor(status);
  }

  // Calculate route progress
  double getRouteProgress(RouteModel route) {
    // This logic might need to be moved to the service or model
    if (route.stops.isEmpty) return 0.0;
    // Assuming the service will have a method that can get completed stops for a route.
    // This is a placeholder implementation.
    return 0.0; // Placeholder
  }

  // Calculate estimated duration
  String getEstimatedDuration(RouteModel route) {
    // Placeholder implementation
    return "N/A";
  }

  // Format date for display
  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Format time for display
  String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Get route duration (Legacy method for old routes with startTime/endTime)
  String getRouteDuration(RouteModel route) {
    final startTime = route.startTime;
    final endTime = route.endTime;

    // New routes don't have startTime/endTime fields
    if (startTime == null || endTime == null) {
      return 'N/A';
    }
    final duration = endTime.difference(startTime);
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }

  // Stream all routes for a company as a list of maps
  Stream<List<Map<String, dynamic>>> streamCompanyRoutes(String companyId) {
    return _routeService
        .streamCompanyRoutes(companyId)
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id,
                ...data,
              };
            }).toList());
  }
} 