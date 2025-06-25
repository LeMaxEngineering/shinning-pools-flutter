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
    return Customer.fromFirestore(doc);
  }

  // Stream a customer's updates
  Stream<Customer> streamCustomer(String customerId) {
    return _firestoreService.streamDocument(
      _firestoreService.customersCollection,
      customerId,
    ).map((doc) => Customer.fromFirestore(doc));
  }

  // Update customer details
  Future<void> updateCustomer(String customerId, Map<String, dynamic> data) async {
    // Add updatedAt timestamp
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    
    await _firestoreService.updateDocument(
      _firestoreService.customersCollection,
      customerId,
      data,
    );
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
    return _firestoreService.streamCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList());
  }

  // Add service record to customer history
  Future<void> addServiceRecord(
    String customerId,
    Map<String, dynamic> serviceData,
  ) async {
    final customer = await getCustomer(customerId);
    final currentHistory = List<Map<String, dynamic>>.from(customer.serviceHistory);
    
    currentHistory.add({
      ...serviceData,
      'date': Timestamp.fromDate(DateTime.now()),
    });

    await updateCustomer(customerId, {
      'serviceHistory': currentHistory,
    });
  }

  // Update customer preferences
  Future<void> updatePreferences(
    String customerId,
    Map<String, dynamic> preferences,
  ) async {
    await updateCustomer(customerId, {
      'preferences': preferences,
    });
  }

  // Update customer billing information
  Future<void> updateBillingInfo(
    String customerId,
    Map<String, dynamic> billingInfo,
  ) async {
    await updateCustomer(customerId, {
      'billingInfo': billingInfo,
    });
  }

  // Update customer notes
  Future<void> updateNotes(String customerId, String notes) async {
    await updateCustomer(customerId, {
      'notes': notes,
    });
  }

  // Get customers by service type
  Stream<List<Customer>> streamCustomersByServiceType(
    String companyId,
    String serviceType,
  ) {
    return _firestoreService.streamCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('serviceType', isEqualTo: serviceType),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList());
  }

  // Get active customers
  Stream<List<Customer>> streamActiveCustomers(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'active'),
    ).map((snapshot) => snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList());
  }

  // Get all customers for a company as a Future
  Future<List<Customer>> getCompanyCustomers(String companyId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.customersCollection,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
    return snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList();
  }
}