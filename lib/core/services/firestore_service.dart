import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get poolsCollection => _firestore.collection('pools');
  CollectionReference get customersCollection => _firestore.collection('customers');
  CollectionReference get workersCollection => _firestore.collection('workers');
  CollectionReference get workerInvitationsCollection => _firestore.collection('worker_invitations');
  CollectionReference get routesCollection => _firestore.collection('routes');
  CollectionReference get reportsCollection => _firestore.collection('reports');
  CollectionReference get companiesCollection => _firestore.collection('companies');

  // Generic CRUD operations
  Future<DocumentReference> addDocument(
    CollectionReference collection,
    Map<String, dynamic> data,
  ) async {
    return await collection.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDocument(
    CollectionReference collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await collection.doc(documentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument(
    CollectionReference collection,
    String documentId,
  ) async {
    await collection.doc(documentId).delete();
  }

  Future<DocumentSnapshot> getDocument(
    CollectionReference collection,
    String documentId,
  ) async {
    return await collection.doc(documentId).get();
  }

  Stream<QuerySnapshot> streamCollection(
    CollectionReference collection, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = collection;
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  Stream<DocumentSnapshot> streamDocument(
    CollectionReference collection,
    String documentId,
  ) {
    return collection.doc(documentId).snapshots();
  }

  Future<QuerySnapshot> getCollection(
    CollectionReference collection, {
    Query Function(Query)? queryBuilder,
  }) async {
    Query query = collection;
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }
}