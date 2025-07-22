import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shinning_pools_flutter/features/pools/models/pool.dart';

class PoolRepository {
  final FirestoreService _firestoreService;

  PoolRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new pool
  Future<DocumentReference> createPool({
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
    final poolData = {
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'size': size,
      'specifications': specifications,
      'status': status,
      'assignedWorkerId': assignedWorkerId,
      'companyId': companyId,
      'monthlyCost': monthlyCost,
      'photoUrl': photoUrl,
      'maintenanceHistory': [],
      'lastMaintenance': null,
      'nextMaintenanceDate': null,
      'waterQualityMetrics': {
        'ph': null,
        'chlorine': null,
        'alkalinity': null,
        'lastTested': null,
      },
      'equipment': specifications['equipment'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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

  // Get all pools for a company (synchronous for dashboard stats)
  Future<QuerySnapshot> getCompanyPools(String companyId) async {
    return await _firestoreService.getCollection(
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
      queryBuilder: (query) =>
          query.where('assignedWorkerId', isEqualTo: workerId),
    );
  }

  // Get all pools assigned to a worker (synchronous)
  Future<QuerySnapshot> getWorkerPools(String workerId) async {
    return await _firestoreService.getCollection(
      _firestoreService.poolsCollection,
      queryBuilder: (query) =>
          query.where('assignedWorkerId', isEqualTo: workerId),
    );
  }

  // Add maintenance record to separate collection
  Future<DocumentReference> addMaintenanceRecord(
    String poolId,
    Map<String, dynamic> maintenanceData,
    String performedById,
    String performedByName,
  ) async {
    // Get pool info for reference
    final pool = await getPool(poolId);
    final poolData = pool.data() as Map<String, dynamic>;

    // Create maintenance record in separate collection
    final maintenanceRecord = {
      'poolId': poolId,
      'poolName': poolData['name'],
      'customerId': poolData['customerId'],
      'customerName': poolData['customerName'],
      'companyId': poolData['companyId'],
      'assignedWorkerId': poolData['assignedWorkerId'],
      'performedById': performedById,
      'performedByName': performedByName,
      ...maintenanceData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final maintenanceRef = await _firestoreService.addDocument(
      _firestoreService.pool_maintenances_collection,
      maintenanceRecord,
    );

    // Update pool with last maintenance info (not the full history)
    await updatePool(poolId, {
      'lastMaintenance': FieldValue.serverTimestamp(),
      'lastMaintenanceId': maintenanceRef.id,
      'nextMaintenanceDate': maintenanceData['nextMaintenanceDate'],
    });

    return maintenanceRef;
  }

  // Get maintenance records for a pool
  Stream<QuerySnapshot> streamPoolMaintenanceRecords(String poolId) {
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) => query
          .where('poolId', isEqualTo: poolId)
          .orderBy('date', descending: true),
    );
  }

  // Get maintenance records for a company
  Stream<QuerySnapshot> streamCompanyMaintenanceRecords(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .orderBy('date', descending: true),
    );
  }

  // Get maintenance records for a worker
  Stream<QuerySnapshot> streamWorkerMaintenanceRecords(String workerId) {
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) => query
          .where('performedBy', isEqualTo: workerId)
          .orderBy('date', descending: true),
    );
  }

  // Get maintenance records for a customer
  Stream<QuerySnapshot> streamCustomerMaintenanceRecords(String customerId) {
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) => query
          .where('customerId', isEqualTo: customerId)
          .orderBy('date', descending: true),
    );
  }

  // Get maintenance records by date range
  Future<QuerySnapshot> getMaintenanceRecordsByDateRange(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _firestoreService.getCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true),
    );
  }

  // Update maintenance record
  Future<void> updateMaintenanceRecord(
    String maintenanceId,
    Map<String, dynamic> data,
  ) async {
    await _firestoreService.updateDocument(
      _firestoreService.pool_maintenances_collection,
      maintenanceId,
      data,
    );
  }

  // Delete maintenance record
  Future<void> deleteMaintenanceRecord(String maintenanceId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.pool_maintenances_collection,
      maintenanceId,
    );
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
    await updatePool(poolId, {'equipment': equipment});
  }

  // Stream last 20 maintenance records for a company with optional filters
  Stream<QuerySnapshot> streamRecentCompanyMaintenances({
    required String companyId,
    String? poolId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) {
        query = query.where('companyId', isEqualTo: companyId);
        if (poolId != null) {
          query = query.where('poolId', isEqualTo: poolId);
        }
        if (status != null && status.isNotEmpty) {
          query = query.where('status', isEqualTo: status);
        }
        if (startDate != null) {
          query = query.where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
        }
        if (endDate != null) {
          query = query.where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
        }
        return query.orderBy('date', descending: true).limit(20);
      },
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
    return _firestoreService.streamCollection(
      _firestoreService.pool_maintenances_collection,
      queryBuilder: (query) {
        query = query.where('performedBy', isEqualTo: workerId);
        if (poolId != null) {
          query = query.where('poolId', isEqualTo: poolId);
        }
        if (status != null && status.isNotEmpty) {
          query = query.where('status', isEqualTo: status);
        }
        if (startDate != null) {
          query = query.where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          );
        }
        if (endDate != null) {
          query = query.where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          );
        }
        return query.orderBy('date', descending: true).limit(20);
      },
    );
  }

  Future<Map<String, bool>> getMaintenanceStatusForPools(
    List<String> poolIds,
    String dateString, {
    String? companyId,
  }) async {
    Map<String, bool> maintenanceStatuses = {};

    // If no companyId provided, we can't query due to security rules
    if (companyId == null) {
      print(
        'Warning: No companyId provided for maintenance status query. Setting all to false.',
      );
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = false;
      }
      return maintenanceStatuses;
    }

    // Parse the date string to DateTime (in UTC to match Firestore timestamps)
    DateTime? targetDate;
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        targetDate = DateTime.utc(
          int.parse(parts[0]), // year
          int.parse(parts[1]), // month
          int.parse(parts[2]), // day
        );
      }
    } catch (e) {
      print('Error parsing date string $dateString: $e');
      // Return all false if date parsing fails
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = false;
      }
      return maintenanceStatuses;
    }

    if (targetDate == null) {
      print('Could not parse date string: $dateString');
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = false;
      }
      return maintenanceStatuses;
    }

    // Create start and end of day for the target date (in UTC to match Firestore timestamps)
    final startOfDay = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final endOfDay = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
      999,
    );

    print('🔍 Checking maintenance status for date: $dateString');
    print(
      '🔍 Date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}',
    );
    print(
      '🔍 Target date parts: Year=${targetDate.year}, Month=${targetDate.month}, Day=${targetDate.day}',
    );

    for (String poolId in poolIds) {
      try {
        // Query the maintenance collection for the given pool, date range, and company
        QuerySnapshot maintenanceQuery = await _firestoreService.getCollection(
          _firestoreService.pool_maintenances_collection,
          queryBuilder: (query) => query
              .where('poolId', isEqualTo: poolId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
              .where('companyId', isEqualTo: companyId),
        );

        // If no results found, try a broader query without date range (for debugging)
        if (maintenanceQuery.docs.isEmpty) {
          print(
            '🔍 No maintenance records found with date range, trying broader query...',
          );
          QuerySnapshot broaderQuery = await _firestoreService.getCollection(
            _firestoreService.pool_maintenances_collection,
            queryBuilder: (query) => query
                .where('poolId', isEqualTo: poolId)
                .where('companyId', isEqualTo: companyId)
                .orderBy('date', descending: true)
                .limit(5),
          );

          if (broaderQuery.docs.isNotEmpty) {
            print(
              '📋 Found ${broaderQuery.docs.length} maintenance record(s) for pool $poolId (all time):',
            );
            for (final doc in broaderQuery.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final recordDate = data['date'];
              print('  - Record ID: ${doc.id}');
              print('  - Date: $recordDate (${recordDate.runtimeType})');
              print('  - Status: ${data['status']}');
              print('  - Performed By: ${data['performedByName']}');
            }
          }
        }

        // If there are any maintenance records for the pool on the given date, set the status to true
        final hasMaintenance = maintenanceQuery.docs.isNotEmpty;
        maintenanceStatuses[poolId] = hasMaintenance;
        print(
          '🏊 Pool $poolId: ${hasMaintenance ? 'Maintained' : 'Not Maintained'} on $dateString',
        );

        // Debug: Print query details
        print('🔍 Query details for pool $poolId:');
        print(
          '  - Date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}',
        );
        print('  - Company ID: $companyId');
        print('  - Records found: ${maintenanceQuery.docs.length}');

        // Debug: Print maintenance records found
        if (maintenanceQuery.docs.isNotEmpty) {
          print(
            '📋 Found ${maintenanceQuery.docs.length} maintenance record(s) for pool $poolId:',
          );
          for (final doc in maintenanceQuery.docs) {
            final data = doc.data() as Map<String, dynamic>;
            print('  - Record ID: ${doc.id}');
            print('  - Date: ${data['date']}');
            print('  - Status: ${data['status']}');
            print('  - Performed By: ${data['performedByName']}');
          }
        } else {
          print(
            '❌ No maintenance records found for pool $poolId on $dateString',
          );
        }
      } catch (e) {
        print('Error getting maintenance status for pool $poolId: $e');
        maintenanceStatuses[poolId] =
            false; // Default to false in case of error
      }
    }
    return maintenanceStatuses;
  }

  Future<void> updatePoolAddress(
    String poolId,
    String newAddress,
    double newLat,
    double newLng,
  ) async {
    try {
      await _firestoreService.poolsCollection.doc(poolId).update({
        'address': newAddress,
        'latitude': newLat,
        'longitude': newLng,
        'lastAddressUpdate': FieldValue.serverTimestamp(),
      });
      print(
        '✅ Pool address updated successfully in Firestore for pool ID: $poolId',
      );
    } catch (e) {
      print(
        '❌ Error updating pool address in Firestore for pool ID: $poolId - $e',
      );
      throw Exception('Failed to update pool address.');
    }
  }
}
