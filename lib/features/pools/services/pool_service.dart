import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/pool_repository.dart';

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
        _pools = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Create a new pool
  Future<bool> createPool({
    required String customerId,
    required String name,
    required String address,
    required double size,
    required Map<String, dynamic> specifications,
    required String status,
    String? assignedWorkerId,
    String? companyId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.createPool(
        customerId: customerId,
        name: name,
        address: address,
        size: size,
        specifications: specifications,
        status: status,
        assignedWorkerId: assignedWorkerId,
        companyId: companyId,
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
        return {
          'id': doc.id,
          ...data,
        };
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Add maintenance record
  Future<bool> addMaintenanceRecord(
    String poolId,
    Map<String, dynamic> maintenanceData,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _poolRepository.addMaintenanceRecord(poolId, maintenanceData);

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
    return _pools.where((pool) => pool['assignedWorkerId'] == workerId).toList();
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
} 