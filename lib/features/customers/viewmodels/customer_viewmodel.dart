import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/customer_repository.dart';
import '../../../core/services/auth_service.dart';
import '../models/customer.dart';

class CustomerViewModel extends ChangeNotifier {
  final CustomerRepository _customerRepository;
  final AuthService _authService;

  CustomerViewModel({
    required CustomerRepository customerRepository,
    required AuthService authService,
  }) : _customerRepository = customerRepository,
       _authService = authService {
    // print('CustomerViewModel: Constructor called');
  }

  @override
  void dispose() {
    // print('CustomerViewModel: dispose() called');
    super.dispose();
  }

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _typeFilter = 'All';
  String _statusFilter = 'All';
  String? _customerName;

  // Getters
  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  String? get customerName => _customerName;

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
      // print('CustomerViewModel: loadCustomers() called');
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        // print('CustomerViewModel: User not authenticated');
        _setError('User not authenticated');
        _setLoading(false);
        return;
      }

      // print('CustomerViewModel: User authenticated - Email: ${currentUser.email}, Role: ${currentUser.role}');

      // Get company ID from user
      String companyId;
      if (currentUser.role.isRoot) {
        // Root user can see all customers (for now, we'll use a placeholder)
        // In a real app, you might want to show customers from all companies
        companyId = 'all';
      } else {
        companyId = currentUser.companyId ?? '';
      }

      // print('CustomerViewModel: Loading customers for companyId: $companyId');
      // print('CustomerViewModel: Current user role: ${currentUser.role}');
      // print('CustomerViewModel: Current user email: ${currentUser.email}');
      // print('CustomerViewModel: Current user companyId: ${currentUser.companyId}');

      if (companyId.isEmpty && !currentUser.role.isRoot) {
        // print('CustomerViewModel: Company ID not found');
        _setError('Company ID not found');
        _setLoading(false);
        return;
      }

      // print('CustomerViewModel: Setting up stream...');
      // Stream customers
      _customerRepository.streamCompanyCustomers(companyId).listen(
        (customers) {
          // print('CustomerViewModel: Stream callback received ${customers.length} customers');
          // Filter out any null or malformed customers
          final validCustomers = customers.where((c) => c != null && c.id.isNotEmpty).toList();
          // print('CustomerViewModel: Valid customers: ${validCustomers.length}');
          
          // Use a more defensive approach to prevent setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (validCustomers.isEmpty) {
              // print('CustomerViewModel: No valid customers found, setting error');
              _setError('No valid customers found for this company.');
            } else {
              // print('CustomerViewModel: Clearing error, setting customers');
              _setError(''); // Clear any previous errors
            }
            
            _customers = validCustomers;
            // print('CustomerViewModel: Calling _applyFilters()');
            _applyFilters();
            // print('CustomerViewModel: Setting loading to false');
            _setLoading(false);
          });
        },
        onError: (error) {
          // print('CustomerViewModel: Stream error: $error');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setError('Failed to load customers: $error');
            _setLoading(false);
          });
        },
      );
      // print('CustomerViewModel: Stream setup completed');
    } catch (e) {
      // print('CustomerViewModel: Exception in loadCustomers: $e');
      _setError('Failed to load customers: $e');
      _setLoading(false);
    }
  }

  // Create a new customer
  Future<bool> createCustomer({
    required String name,
    String? email,
    required String phone,
    required String address,
    String? serviceType,
    String status = 'active',
    String? photoUrl,
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
        email: email ?? '',
        phone: phone,
        address: address,
        companyId: companyId,
        serviceType: serviceType,
        status: status,
        photoUrl: photoUrl,
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

      // print('CustomerViewModel: Updating customer $customerId with data: $data');
      await _customerRepository.updateCustomer(customerId, data);
      
      _setLoading(false);
      return true;
    } catch (e) {
      // print('CustomerViewModel: Update failed with error: $e');
      // print('CustomerViewModel: Update data was: $data');
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear error
  void clearError() {
    _error = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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

  // Load customer name by ID
  Future<void> loadCustomerName(String customerId) async {
    try {
      // Don't set loading state here as it can cause setState during build
      // Just load the data directly
      final customer = await _customerRepository.getCustomer(customerId);
      if (customer != null) {
        _customerName = customer.name;
        // Only notify if the name actually changed
        if (_customerName != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        }
      }
    } catch (e) {
      _error = e.toString();
      _customerName = null;
      // Only notify if there was an error and we need to update the UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Debug method to test customer loading
  Future<void> debugLoadCustomers() async {
    // print('=== CUSTOMER VIEWMODEL DEBUG ===');
    // print('Current customers count: ${_customers.length}');
    // print('Is loading: $_isLoading');
    // print('Error: $_error');
    
    final currentUser = _authService.currentUser;
    // print('Current user: ${currentUser?.email}');
    // print('Current user role: ${currentUser?.role}');
    // print('Current user companyId: ${currentUser?.companyId}');
    
    if (currentUser != null) {
      final companyId = currentUser.role.isRoot ? 'all' : (currentUser.companyId ?? '');
      // print('Using companyId: $companyId');
      
      try {
        // print('Testing stream directly...');
        final stream = _customerRepository.streamCompanyCustomers(companyId);
        final subscription = stream.listen(
          (customers) {
            // print('DEBUG: Stream received ${customers.length} customers');
            for (int i = 0; i < customers.length; i++) {
              final customer = customers[i];
              // print('  ${i + 1}. ${customer.name} (${customer.email}) - CompanyId: ${customer.companyId}');
            }
          },
          onError: (error) {
            // print('DEBUG: Stream error: $error');
          },
        );
        
        // Wait a bit and then cancel
        await Future.delayed(const Duration(seconds: 3));
        subscription.cancel();
        // print('DEBUG: Stream test completed');
      } catch (e) {
        // print('DEBUG: Exception testing stream: $e');
      }
    }
    // print('=== END DEBUG ===');
  }
} 