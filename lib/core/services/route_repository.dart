import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class RouteRepository {
  final FirestoreService _firestoreService;

  RouteRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new route
  Future<DocumentReference> createRoute({
    required String createdById,
    required String companyId,
    required DateTime date,
    required List<Map<String, dynamic>> stops,
    String status = 'pending',
    String? routeName,
    String? createdByName,
  }) async {
    final routeData = {
      'createdById': createdById,
      'createdByName': createdByName,
      'companyId': companyId,
      'date': Timestamp.fromDate(date),
      'stops': stops,
      'status': status,
      'totalDistance': 0.0,
      'completedStops': 0,
      'totalStops': stops.length,
      'notes': '',
      if (routeName != null && routeName.isNotEmpty) 'routeName': routeName,
    };

    return await _firestoreService.addDocument(
      _firestoreService.routesCollection,
      routeData,
    );
  }

  // Get a route by ID
  Future<DocumentSnapshot> getRoute(String routeId) async {
    return await _firestoreService.getDocument(
      _firestoreService.routesCollection,
      routeId,
    );
  }

  // Stream a route's updates
  Stream<DocumentSnapshot> streamRoute(String routeId) {
    return _firestoreService.streamDocument(
      _firestoreService.routesCollection,
      routeId,
    );
  }

  // Update route details
  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(
      _firestoreService.routesCollection,
      routeId,
      data,
    );
  }

  // Delete a route
  Future<void> deleteRoute(String routeId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.routesCollection,
      routeId,
    );
  }

  // Get all routes for a company
  Future<QuerySnapshot> getRoutesForCompany(String companyId) async {
    return await _firestoreService.routesCollection
        .where('companyId', isEqualTo: companyId)
        .get();
  }

  // Stream all routes for a company
  Stream<QuerySnapshot> streamCompanyRoutes(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.routesCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
  }

  // Get all routes for a worker
  Stream<QuerySnapshot> streamWorkerRoutes(String workerId) {
    return _firestoreService.streamCollection(
      _firestoreService.routesCollection,
      queryBuilder: (query) => query.where('workerId', isEqualTo: workerId),
    );
  }

  // Get routes by date range
  Stream<QuerySnapshot> streamRoutesByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestoreService.streamCollection(
      _firestoreService.routesCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate)),
    );
  }

  // Start route
  Future<void> startRoute(String routeId) async {
    await updateRoute(routeId, {
      'status': 'in_progress',
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // Complete route
  Future<void> completeRoute(
    String routeId, {
    required double totalDistance,
    String? notes,
  }) async {
    await updateRoute(routeId, {
      'status': 'completed',
      'endTime': FieldValue.serverTimestamp(),
      'totalDistance': totalDistance,
      if (notes != null) 'notes': notes,
    });
  }

  // Update route stop status
  Future<void> updateStopStatus(
    String routeId,
    int stopIndex,
    String status,
    Map<String, dynamic>? details,
  ) async {
    final route = await getRoute(routeId);
    final stops = List<Map<String, dynamic>>.from(route.get('stops'));
    
    stops[stopIndex] = {
      ...stops[stopIndex],
      'status': status,
      'completedAt': status == 'completed' ? FieldValue.serverTimestamp() : null,
      if (details != null) ...details,
    };

    final completedStops = stops.where((stop) => stop['status'] == 'completed').length;

    await updateRoute(routeId, {
      'stops': stops,
      'completedStops': completedStops,
    });
  }

  // Get today's routes
  Stream<QuerySnapshot> streamTodayRoutes(String companyId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return streamRoutesByDateRange(companyId, startOfDay, endOfDay);
  }

  // Get active routes
  Stream<QuerySnapshot> streamActiveRoutes(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.routesCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['pending', 'in_progress']),
    );
  }
}