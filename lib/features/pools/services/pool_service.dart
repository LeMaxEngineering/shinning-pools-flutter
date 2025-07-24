import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/pool_repository.dart';
import 'package:flutter/widgets.dart';

class PoolService extends ChangeNotifier {
  final PoolRepository _poolRepository;

  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  String? _error;
  Stream<QuerySnapshot>? _poolsStream;

  PoolService({PoolRepository? poolRepository})
    : _poolRepository = poolRepository ?? PoolRepository();

  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize pools stream for a company
  void initializePoolsStream(String companyId) {
    _poolsStream = _poolRepository.streamCompanyPools(companyId);
    _poolsStream?.listen(
      (snapshot) {
        // Use post-frame callback to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pools = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, ...data};
          }).toList();
          _isLoading = false;
          _error = null;
          notifyListeners();
        });
      },
      onError: (error) {
        // Use post-frame callback to prevent setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        });
      },
    );
  }

  // Create a new pool
  Future<bool> createPool({
    required String customerId,
    required String name,
    required String address,
    required double? latitude,
    required double? longitude,
    required double size,
    required Map<String, dynamic> specifications,
    required String status,
    String? assignedWorkerId,
    String? companyId,
    double monthlyCost = 0.0,
    String? photoUrl,
    String? customerEmail,
    String? customerName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.createPool(
        customerId: customerId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        size: size,
        specifications: specifications,
        status: status,
        assignedWorkerId: assignedWorkerId,
        companyId: companyId,
        monthlyCost: monthlyCost,
        photoUrl: photoUrl,
        customerEmail: customerEmail,
        customerName: customerName,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update pool details
  Future<bool> updatePool(String poolId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.updatePool(poolId, data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a pool
  Future<bool> deletePool(String poolId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.deletePool(poolId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get a specific pool
  Future<Map<String, dynamic>?> getPool(String poolId) async {
    try {
      final doc = await _poolRepository.getPool(poolId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get all pools for a company (for dashboard stats)
  Future<List<Map<String, dynamic>>> getCompanyPools(String companyId) async {
    try {
      final querySnapshot = await _poolRepository.getCompanyPools(companyId);
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get all pools assigned to a worker
  Future<List<Map<String, dynamic>>> getWorkerPoolsAsync(
    String workerId,
  ) async {
    try {
      final querySnapshot = await _poolRepository.getWorkerPools(workerId);
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Add maintenance record
  Future<bool> addMaintenanceRecord(
    String poolId,
    Map<String, dynamic> maintenanceData,
    String performedById,
    String performedByName,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.addMaintenanceRecord(
        poolId,
        maintenanceData,
        performedById,
        performedByName,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get maintenance records for a pool
  Stream<QuerySnapshot> getPoolMaintenanceRecords(String poolId) {
    return _poolRepository.streamPoolMaintenanceRecords(poolId);
  }

  // Get maintenance records for a company
  Stream<QuerySnapshot> getCompanyMaintenanceRecords(String companyId) {
    return _poolRepository.streamCompanyMaintenanceRecords(companyId);
  }

  // Get maintenance records for a worker
  Stream<QuerySnapshot> getWorkerMaintenanceRecords(String workerId) {
    return _poolRepository.streamWorkerMaintenanceRecords(workerId);
  }

  // Get maintenance records for a customer
  Stream<QuerySnapshot> getCustomerMaintenanceRecords(String customerId) {
    return _poolRepository.streamCustomerMaintenanceRecords(customerId);
  }

  // Get maintenance records by date range
  Future<List<Map<String, dynamic>>> getMaintenanceRecordsByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _poolRepository
          .getMaintenanceRecordsByDateRange(companyId, startDate, endDate);
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Update water quality metrics
  Future<bool> updateWaterQuality(
    String poolId,
    Map<String, dynamic> metrics,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.updateWaterQuality(poolId, metrics);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update equipment
  Future<bool> updateEquipment(
    String poolId,
    List<Map<String, dynamic>> equipment,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.updateEquipment(poolId, equipment);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get pools by status
  List<Map<String, dynamic>> getPoolsByStatus(String status) {
    return _pools.where((pool) => pool['status'] == status).toList();
  }

  // Get pools by customer
  List<Map<String, dynamic>> getPoolsByCustomer(String customerId) {
    return _pools.where((pool) => pool['customerId'] == customerId).toList();
  }

  // Get pools by assigned worker
  List<Map<String, dynamic>> getPoolsByWorker(String workerId) {
    return _pools
        .where((pool) => pool['assignedWorkerId'] == workerId)
        .toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _poolsStream = null;
    super.dispose();
  }

  // Stream last 20 maintenance records for a company with optional filters
  Stream<QuerySnapshot> streamRecentCompanyMaintenances({
    required String companyId,
    String? poolId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return _poolRepository.streamRecentCompanyMaintenances(
      companyId: companyId,
      poolId: poolId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  // Stream last 20 maintenance records for a worker with optional filters
  Stream<QuerySnapshot> streamRecentWorkerMaintenances({
    required String workerId,
    String? poolId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return _poolRepository.streamRecentWorkerMaintenances(
      workerId: workerId,
      poolId: poolId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  // Check if all pools in a route have been maintained and close the route if so
  Future<bool> checkAndCloseRouteIfComplete(
    String routeId,
    String companyId,
  ) async {
    try {
      print('🔍 Checking if route $routeId should be closed...');

      // Get the route data to find all pool IDs
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeId)
          .get();

      if (!routeDoc.exists) {
        print('❌ Route $routeId not found');
        return false;
      }

      final routeData = routeDoc.data()!;
      final stops = routeData['stops'] ?? [];

      if (stops.isEmpty) {
        print('⚠️ Route $routeId has no pools');
        return false;
      }

      // Convert stops to pool IDs
      List<String> poolIds = [];
      if (stops.isNotEmpty && stops.first is String) {
        poolIds = List<String>.from(stops);
      } else if (stops.isNotEmpty && stops.first is Map<String, dynamic>) {
        poolIds = stops
            .map((stop) => stop['poolId'] ?? stop['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }

      if (poolIds.isEmpty) {
        print('⚠️ No valid pool IDs found in route $routeId');
        return false;
      }

      print(
        '🔍 Checking maintenance status for ${poolIds.length} pools in route $routeId',
      );

      // Check maintenance status for all pools in the route
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final maintenanceStatuses = await _poolRepository
          .getMaintenanceStatusForPools(
            poolIds,
            dateString,
            companyId: companyId,
          );

      // Count maintained pools
      int maintainedPools = 0;
      for (String poolId in poolIds) {
        if (maintenanceStatuses[poolId] == true) {
          maintainedPools++;
          print('✅ Pool $poolId is maintained');
        } else {
          print('❌ Pool $poolId is NOT maintained');
        }
      }

      print(
        '📊 Route completion: $maintainedPools/${poolIds.length} pools maintained',
      );

      // If all pools are maintained, close the route
      if (maintainedPools == poolIds.length) {
        print(
          '🎉 All pools in route $routeId are maintained! Closing route...',
        );

        // Update route status to CLOSED
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(routeId)
            .update({
              'status': 'CLOSED',
              'updatedAt': FieldValue.serverTimestamp(),
              'closedAt': FieldValue.serverTimestamp(),
            });

        // Find and update all active assignments for this route
        final assignmentsSnapshot = await FirebaseFirestore.instance
            .collection('assignments')
            .where('routeId', isEqualTo: routeId)
            .where('status', whereIn: ['Active', 'Hold'])
            .get();

        int updatedAssignments = 0;
        for (final assignmentDoc in assignmentsSnapshot.docs) {
          await assignmentDoc.reference.update({
            'status': 'CLOSED',
            'updatedAt': FieldValue.serverTimestamp(),
            'closedAt': FieldValue.serverTimestamp(),
          });
          updatedAssignments++;
        }

        print(
          '✅ Route $routeId closed successfully. Updated $updatedAssignments assignments.',
        );
        return true;
      } else {
        print(
          '⏳ Route $routeId not ready to close. $maintainedPools/${poolIds.length} pools maintained.',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error checking and closing route: $e');
      return false;
    }
  }

  // Update maintenance record
  Future<bool> updateMaintenanceRecord(
    String maintenanceId,
    Map<String, dynamic> data,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.updateMaintenanceRecord(maintenanceId, data);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete maintenance record
  Future<bool> deleteMaintenanceRecord(String maintenanceId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.deleteMaintenanceRecord(maintenanceId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
