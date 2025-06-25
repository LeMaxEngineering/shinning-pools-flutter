import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class PoolRepository {
  final FirestoreService _firestoreService;

  PoolRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new pool
  Future<DocumentReference> createPool({
    required String customerId,
    required String name,
    required String address,
    required double size,
    required Map<String, dynamic> specifications,
    required String status,
    String? assignedWorkerId,
    String? companyId,
  }) async {
    final poolData = {
      'customerId': customerId,
      'name': name,
      'address': address,
      'size': size,
      'specifications': specifications,
      'status': status,
      'assignedWorkerId': assignedWorkerId,
      'companyId': companyId,
      'maintenanceHistory': [],
      'lastMaintenance': null,
      'nextMaintenanceDate': null,
      'waterQualityMetrics': {
        'ph': null,
        'chlorine': null,
        'alkalinity': null,
        'lastTested': null,
      },
      'equipment': [],
    };

    return await _firestoreService.addDocument(
      _firestoreService.poolsCollection,
      poolData,
    );
  }

  // Get a pool by ID
  Future<DocumentSnapshot> getPool(String poolId) async {
    return await _firestoreService.getDocument(
      _firestoreService.poolsCollection,
      poolId,
    );
  }

  // Stream a pool's updates
  Stream<DocumentSnapshot> streamPool(String poolId) {
    return _firestoreService.streamDocument(
      _firestoreService.poolsCollection,
      poolId,
    );
  }

  // Update pool details
  Future<void> updatePool(String poolId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(
      _firestoreService.poolsCollection,
      poolId,
      data,
    );
  }

  // Delete a pool
  Future<void> deletePool(String poolId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.poolsCollection,
      poolId,
    );
  }

  // Get all pools for a company
  Stream<QuerySnapshot> streamCompanyPools(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.poolsCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
  }

  // Get all pools for a customer
  Stream<QuerySnapshot> streamCustomerPools(String customerId) {
    return _firestoreService.streamCollection(
      _firestoreService.poolsCollection,
      queryBuilder: (query) => query.where('customerId', isEqualTo: customerId),
    );
  }

  // Get all pools assigned to a worker
  Stream<QuerySnapshot> streamWorkerPools(String workerId) {
    return _firestoreService.streamCollection(
      _firestoreService.poolsCollection,
      queryBuilder: (query) => query.where('assignedWorkerId', isEqualTo: workerId),
    );
  }

  // Add maintenance record
  Future<void> addMaintenanceRecord(
    String poolId,
    Map<String, dynamic> maintenanceData,
  ) async {
    final pool = await getPool(poolId);
    final currentHistory = List.from(pool.get('maintenanceHistory') ?? []);
    
    currentHistory.add({
      ...maintenanceData,
      'date': FieldValue.serverTimestamp(),
    });

    await updatePool(poolId, {
      'maintenanceHistory': currentHistory,
      'lastMaintenance': FieldValue.serverTimestamp(),
      'nextMaintenanceDate': maintenanceData['nextMaintenanceDate'],
    });
  }

  // Update water quality metrics
  Future<void> updateWaterQuality(
    String poolId,
    Map<String, dynamic> metrics,
  ) async {
    await updatePool(poolId, {
      'waterQualityMetrics': {
        ...metrics,
        'lastTested': FieldValue.serverTimestamp(),
      },
    });
  }

  // Add or update equipment
  Future<void> updateEquipment(
    String poolId,
    List<Map<String, dynamic>> equipment,
  ) async {
    await updatePool(poolId, {
      'equipment': equipment,
    });
  }
}