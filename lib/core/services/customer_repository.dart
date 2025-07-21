import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinning_pools_flutter/features/customers/models/customer.dart';
import 'firestore_service.dart';

class CustomerRepository {
  final FirestoreService _firestoreService;

  CustomerRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new customer
  Future<Customer> createCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String companyId,
    String? serviceType,
    String status = 'active',
    String? photoUrl,
    Map<String, dynamic>? billingInfo,
  }) async {
    final now = DateTime.now();
    final customerData = {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'companyId': companyId,
      'serviceType': serviceType ?? 'standard',
      'status': status,
      'photoUrl': photoUrl,
      'billingInfo': billingInfo ?? {},
      'serviceHistory': [],
      'preferences': {},
      'notes': '',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final docRef = await _firestoreService.addDocument(
      _firestoreService.customersCollection,
      customerData,
    );

    // Get the created document and return as Customer object
    final doc = await docRef.get();
    return Customer.fromFirestore(doc);
  }

  // Get a customer by ID
  Future<Customer> getCustomer(String customerId) async {
    final doc = await _firestoreService.getDocument(
      _firestoreService.customersCollection,
      customerId,
    );
    if (!doc.exists || doc.data() == null) {
      throw Exception('Customer not found or data is null for ID: $customerId');
    }
    return Customer.fromFirestore(doc);
  }

  // Stream a customer's updates
  Stream<Customer> streamCustomer(String customerId) {
    return _firestoreService
        .streamDocument(_firestoreService.customersCollection, customerId)
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            throw Exception(
              'Customer not found or data is null for ID: $customerId',
            );
          }
          return Customer.fromFirestore(doc);
        });
  }

  // Update customer details
  Future<void> updateCustomer(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Create a copy of the data to avoid modifying the original
      final updateData = Map<String, dynamic>.from(data);

      // Ensure all string fields are properly handled
      for (final key in [
        'name',
        'email',
        'phone',
        'address',
        'serviceType',
        'status',
        'notes',
      ]) {
        if (updateData.containsKey(key) && updateData[key] != null) {
          final value = updateData[key];
          if (value is! String) {
            print(
              'Warning: Converting non-string value for $key: $value (${value.runtimeType})',
            );
            updateData[key] = value.toString();
          }
        }
      }

      // Add updatedAt timestamp
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      // Debug logging to identify problematic fields
      print('CustomerRepository: Update data: $updateData');

      await _firestoreService.updateDocument(
        _firestoreService.customersCollection,
        customerId,
        updateData,
      );
    } catch (e) {
      print('CustomerRepository: Update failed: $e');
      print('CustomerRepository: Failed data: $data');
      rethrow;
    }
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.customersCollection,
      customerId,
    );
  }

  // Get all customers for a company
  Stream<List<Customer>> streamCompanyCustomers(String companyId) {
    return _firestoreService
        .streamCollection(
          _firestoreService.customersCollection,
          queryBuilder: (query) =>
              query.where('companyId', isEqualTo: companyId),
        )
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  // Add service record to customer history
  Future<void> addServiceRecord(
    String customerId,
    Map<String, dynamic> serviceData,
  ) async {
    final customer = await getCustomer(customerId);
    final currentHistory = List<Map<String, dynamic>>.from(
      customer.serviceHistory,
    );

    currentHistory.add({
      ...serviceData,
      'date': Timestamp.fromDate(DateTime.now()),
    });

    await updateCustomer(customerId, {'serviceHistory': currentHistory});
  }

  // Update customer preferences
  Future<void> updatePreferences(
    String customerId,
    Map<String, dynamic> preferences,
  ) async {
    await updateCustomer(customerId, {'preferences': preferences});
  }

  // Update customer billing information
  Future<void> updateBillingInfo(
    String customerId,
    Map<String, dynamic> billingInfo,
  ) async {
    await updateCustomer(customerId, {'billingInfo': billingInfo});
  }

  // Update customer notes
  Future<void> updateNotes(String customerId, String notes) async {
    await updateCustomer(customerId, {'notes': notes});
  }

  // Get customers by service type
  Stream<List<Customer>> streamCustomersByServiceType(
    String companyId,
    String serviceType,
  ) {
    return _firestoreService
        .streamCollection(
          _firestoreService.customersCollection,
          queryBuilder: (query) => query
              .where('companyId', isEqualTo: companyId)
              .where('serviceType', isEqualTo: serviceType),
        )
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  // Get active customers
  Stream<List<Customer>> streamActiveCustomers(String companyId) {
    return _firestoreService
        .streamCollection(
          _firestoreService.customersCollection,
          queryBuilder: (query) => query
              .where('companyId', isEqualTo: companyId)
              .where('status', isEqualTo: 'active'),
        )
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
        );
  }

  // Get all customers for a company as a Future
  Future<List<Customer>> getCompanyCustomers(String companyId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
    return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
  }

  Future<void> debugPrintCustomersForCompany(String companyId) async {
    final query = await _firestoreService.getCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
    if (query.docs.isEmpty) {
      print('No customers found for companyId: ' + companyId);
    } else {
      print('Customers for companyId: ' + companyId);
      for (var doc in query.docs) {
        print('Customer ID: ' + doc.id + ', Data: ' + doc.data().toString());
      }
    }
  }
}
