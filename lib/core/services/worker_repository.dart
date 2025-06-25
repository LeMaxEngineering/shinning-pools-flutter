import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinning_pools_flutter/features/users/models/worker.dart';
import 'firestore_service.dart';

class WorkerRepository {
  final FirestoreService _firestoreService;

  WorkerRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new worker
  Future<Worker> createWorker({
    required String name,
    required String email,
    required String phone,
    required String companyId,
    String status = 'available',
    int poolsAssigned = 0,
    double rating = 0.0,
    String? photoUrl,
  }) async {
    final now = DateTime.now();
    final workerData = {
      'name': name,
      'email': email,
      'phone': phone,
      'companyId': companyId,
      'status': status,
      'poolsAssigned': poolsAssigned,
      'rating': rating,
      'photoUrl': photoUrl,
      'lastActive': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final docRef = await _firestoreService.addDocument(
      _firestoreService.workersCollection,
      workerData,
    );

    // Get the created document and return as Worker object
    final doc = await docRef.get();
    return Worker.fromFirestore(doc);
  }

  // Get a worker by ID
  Future<Worker> getWorker(String workerId) async {
    final doc = await _firestoreService.getDocument(
      _firestoreService.workersCollection,
      workerId,
    );
    return Worker.fromFirestore(doc);
  }

  // Stream a worker's updates
  Stream<Worker> streamWorker(String workerId) {
    return _firestoreService.streamDocument(
      _firestoreService.workersCollection,
      workerId,
    ).map((doc) => Worker.fromFirestore(doc));
  }

  // Update worker details
  Future<void> updateWorker(String workerId, Map<String, dynamic> data) async {
    // Add updatedAt timestamp
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    
    await _firestoreService.updateDocument(
      _firestoreService.workersCollection,
      workerId,
      data,
    );
  }

  // Delete a worker
  Future<void> deleteWorker(String workerId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.workersCollection,
      workerId,
    );
  }

  // Get all workers for a company
  Stream<List<Worker>> streamCompanyWorkers(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.workersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Worker.fromFirestore(doc))
        .toList());
  }

  // Get workers by status
  Stream<List<Worker>> streamWorkersByStatus(
    String companyId,
    String status,
  ) {
    return _firestoreService.streamCollection(
      _firestoreService.workersCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: status),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Worker.fromFirestore(doc))
        .toList());
  }

  // Get active workers
  Stream<List<Worker>> streamActiveWorkers(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.workersCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['active', 'on_route', 'available']),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Worker.fromFirestore(doc))
        .toList());
  }

  // Update worker status
  Future<void> updateWorkerStatus(String workerId, String status) async {
    await updateWorker(workerId, {
      'status': status,
      'lastActive': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update worker's assigned pools count
  Future<void> updatePoolsAssigned(String workerId, int poolsAssigned) async {
    await updateWorker(workerId, {
      'poolsAssigned': poolsAssigned,
    });
  }

  // Update worker rating
  Future<void> updateWorkerRating(String workerId, double rating) async {
    await updateWorker(workerId, {
      'rating': rating,
    });
  }

  // Get all workers for a company as a Future
  Future<List<Worker>> getCompanyWorkers(String companyId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.workersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
    return snapshot.docs
        .map((doc) => Worker.fromFirestore(doc))
        .toList();
  }
} 