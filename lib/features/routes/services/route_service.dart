import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/route_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_auth_repository.dart';
import '../../../features/pools/models/pool.dart';
import '../../../features/users/models/worker.dart';
import '../models/route.dart';

class RouteService extends ChangeNotifier {
  final RouteRepository _routeRepository;
  final AuthService _authService;

  RouteService({
    RouteRepository? routeRepository,
    AuthService? authService,
  }) : _routeRepository = routeRepository ?? RouteRepository(),
       _authService = authService ?? AuthService(FirebaseAuthRepository());

  // State
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentRoute;

  // Getters
  List<Map<String, dynamic>> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentRoute => _currentRoute;

  // Get routes for the current company
  Future<List<DocumentSnapshot>> getRoutesForCompany() async {
    final currentUser = _authService.currentUser;
    if (currentUser?.companyId == null) {
      throw Exception('User not associated with a company');
    }
    final companyId = currentUser!.companyId!;
    final snapshot = await _routeRepository.getRoutesForCompany(companyId);
    return snapshot.docs;
  }


  // Load routes for current user
  Future<void> loadRoutes() async {
    try {
      _setLoading(true);
      _error = null;

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _error = 'User not authenticated';
        return;
      }

      Stream<dynamic> routesStream;
      
      if (currentUser.role == 'worker') {
        routesStream = _routeRepository.streamWorkerRoutes(currentUser.id);
      } else if (currentUser.role == 'admin' || currentUser.role == 'root') {
        final companyId = currentUser.companyId;
        if (companyId == null) {
          _error = 'User not associated with a company';
          return;
        }
        routesStream = _routeRepository.streamCompanyRoutes(companyId);
      } else {
        _error = 'Invalid user role for route access';
        return;
      }

      routesStream.listen(
        (snapshot) {
          _routes = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Sort routes by date (newest first)
          _routes.sort((a, b) {
            final dateA = (a['date'] as dynamic).toDate() as DateTime;
            final dateB = (b['date'] as dynamic).toDate() as DateTime;
            return dateB.compareTo(dateA);
          });
          
          _setLoading(false);
        },
        onError: (error) {
          _error = error.toString();
          _setLoading(false);
        },
      );
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Create a new route
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

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _error = 'User not authenticated';
        return false;
      }

      final companyId = currentUser.companyId;
      if (companyId == null) {
        _error = 'User not associated with a company';
        return false;
      }

      await _routeRepository.createRoute(
        createdById: createdById,
        companyId: companyId,
        date: date,
        stops: stops,
        status: status,
        routeName: routeName,
        createdByName: createdByName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Start a route
  Future<bool> startRoute(String routeId) async {
    try {
      _setLoading(true);
      _error = null;

      await _routeRepository.startRoute(routeId);
      
      // Update local state
      final routeIndex = _routes.indexWhere((route) => route['id'] == routeId);
      if (routeIndex != -1) {
        _routes[routeIndex]['status'] = 'in_progress';
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Complete a route
  Future<bool> completeRoute(
    String routeId, {
    required double totalDistance,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await _routeRepository.completeRoute(
        routeId,
        totalDistance: totalDistance,
        notes: notes,
      );

      // Update local state
      final routeIndex = _routes.indexWhere((route) => route['id'] == routeId);
      if (routeIndex != -1) {
        _routes[routeIndex]['status'] = 'completed';
        _routes[routeIndex]['totalDistance'] = totalDistance;
        if (notes != null) {
          _routes[routeIndex]['notes'] = notes;
        }
        notifyListeners();
      }

      _setLoading(false);
      return true;
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

      await _routeRepository.updateStopStatus(
        routeId,
        stopIndex,
        status,
        details,
      );

      // Update local state
      final routeIndex = _routes.indexWhere((route) => route['id'] == routeId);
      if (routeIndex != -1) {
        final stops = List<Map<String, dynamic>>.from(_routes[routeIndex]['stops']);
        stops[stopIndex] = {
          ...stops[stopIndex],
          'status': status,
          'completedAt': status == 'completed' ? DateTime.now() : null,
          if (details != null) ...details,
        };
        
        _routes[routeIndex]['stops'] = stops;
        _routes[routeIndex]['completedStops'] = stops.where((stop) => stop['status'] == 'completed').length;
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Get route by ID
  Future<Map<String, dynamic>?> getRoute(String routeId) async {
    try {
      final doc = await _routeRepository.getRoute(routeId);
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Delete route
  Future<bool> deleteRoute(String routeId) async {
    try {
      _setLoading(true);
      _error = null;

      await _routeRepository.deleteRoute(routeId);

      // Remove from local state
      _routes.removeWhere((route) => route['id'] == routeId);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Get routes by date range
  Future<List<Map<String, dynamic>>> getRoutesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      final companyId = currentUser?.companyId;
      if (companyId == null) {
        return [];
      }

      final snapshot = await _routeRepository.streamRoutesByDateRange(
        companyId,
        startDate,
        endDate,
      ).first;

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get today's routes
  Future<List<Map<String, dynamic>>> getTodayRoutes() async {
    try {
      final currentUser = _authService.currentUser;
      final companyId = currentUser?.companyId;
      if (companyId == null) {
        return [];
      }

      final snapshot = await _routeRepository.streamTodayRoutes(companyId).first;

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Get active routes
  Future<List<Map<String, dynamic>>> getActiveRoutes() async {
    try {
      final currentUser = _authService.currentUser;
      final companyId = currentUser?.companyId;
      if (companyId == null) {
        return [];
      }

      final snapshot = await _routeRepository.streamActiveRoutes(companyId).first;

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Stream all routes for a company
  Stream<QuerySnapshot> streamCompanyRoutes(String companyId) {
    return _routeRepository.streamCompanyRoutes(companyId);
  }

  // Set current route (for tracking)
  void setCurrentRoute(Map<String, dynamic>? route) {
    _currentRoute = route;
    notifyListeners();
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
    switch (status) {
      case 'pending':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color getRouteStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate route progress
  double getRouteProgress(RouteModel route) {
    if (route.stops.isEmpty) return 0.0;
    // This logic needs to be more robust. Assuming stops are maps with a 'status' key.
    // This part of your application seems to have inconsistencies in data models.
    // For now, this is a placeholder.
    return 0.0;
  }

  // Calculate estimated duration
  String getEstimatedDuration(RouteModel route) {
    // Placeholder
    return 'N/A';
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    await _routeRepository.updateRoute(routeId, data);
  }
} 