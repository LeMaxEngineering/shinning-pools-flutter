import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/services/customer_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/role.dart';
import '../models/customer.dart';

class CustomerViewModel extends ChangeNotifier {
  final CustomerRepository _customerRepository;
  final AuthService _authService;

  CustomerViewModel({
    required CustomerRepository customerRepository,
    required AuthService authService,
  }) : _customerRepository = customerRepository,
       _authService = authService;

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _typeFilter = 'All';
  String _statusFilter = 'All';

  // Getters
  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;

  // Statistics
  int get totalCustomers => _customers.length;
  int get premiumCustomers => _customers.where((c) => c.serviceType.toLowerCase() == 'premium').length;
  int get activeCustomers => _customers.where((c) => c.status.toLowerCase() == 'active').length;

  // Initialize and load customers
  Future<void> initialize() async {
    await loadCustomers();
  }

  // Load customers for the current company
  Future<void> loadCustomers() async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return;
      }

      // Get company ID from user
      String companyId;
      if (currentUser.role.isRoot) {
        // Root user can see all customers (for now, we'll use a placeholder)
        // In a real app, you might want to show customers from all companies
        companyId = 'all';
      } else {
        companyId = currentUser.companyId ?? '';
      }

      if (companyId.isEmpty && !currentUser.role.isRoot) {
        _setError('Company ID not found');
        return;
      }

      // Stream customers
      _customerRepository.streamCompanyCustomers(companyId).listen(
        (customers) {
          _customers = customers;
          _applyFilters();
          _setLoading(false);
        },
        onError: (error) {
          _setError('Failed to load customers: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to load customers: $e');
      _setLoading(false);
    }
  }

  // Create a new customer
  Future<bool> createCustomer({
    required String name,
    required String email,
    required String phone,
    required String address,
    String? serviceType,
    String status = 'active',
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      String companyId;
      if (currentUser.role.isRoot) {
        // For root user, we need to determine which company to assign to
        // For now, we'll use a placeholder
        companyId = 'default_company';
      } else {
        companyId = currentUser.companyId ?? '';
      }

      if (companyId.isEmpty) {
        _setError('Company ID not found');
        return false;
      }

      await _customerRepository.createCustomer(
        name: name,
        email: email,
        phone: phone,
        address: address,
        companyId: companyId,
        serviceType: serviceType,
        status: status,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create customer: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update customer
  Future<bool> updateCustomer(String customerId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError('');

      await _customerRepository.updateCustomer(customerId, data);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update customer: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    try {
      _setLoading(true);
      _setError('');

      await _customerRepository.deleteCustomer(customerId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete customer: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Update type filter
  void updateTypeFilter(String filter) {
    _typeFilter = filter;
    _applyFilters();
  }

  // Update status filter
  void updateStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilters();
  }

  // Apply filters to customers
  void _applyFilters() {
    _filteredCustomers = _customers.where((customer) {
      final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _typeFilter == 'All' || customer.serviceTypeDisplay == _typeFilter;
      final matchesStatus = _statusFilter == 'All' || customer.statusDisplay == _statusFilter;
      
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Get customer by ID
  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((customer) => customer.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh customers
  Future<void> refresh() async {
    await loadCustomers();
  }
} 