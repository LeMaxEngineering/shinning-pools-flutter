import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../models/customer.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerViewModel>(context, listen: false).initialize();
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Premium':
        return Colors.purple;
      case 'Standard':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addNewCustomer() async {
    final viewModel = Provider.of<CustomerViewModel>(context, listen: false);
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      if (result['action'] == 'delete') {
        return;
      }
      
      // Create new customer
      final success = await viewModel.createCustomer(
        name: result['name'],
        email: result['email'],
        phone: result['phone'],
        address: result['address'],
        serviceType: result['type'],
        status: result['status'],
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create customer: ${viewModel.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editCustomer(Customer customer) async {
    final viewModel = Provider.of<CustomerViewModel>(context, listen: false);
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: customer)),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      if (result['action'] == 'delete') {
        // Handle delete action
        final success = await viewModel.deleteCustomer(customer.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${customer.name} has been deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete customer: ${viewModel.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }
      
      // Update customer
      final success = await viewModel.updateCustomer(customer.id, {
        'name': result['name'],
        'email': result['email'],
        'phone': result['phone'],
        'address': result['address'],
        'serviceType': result['type'],
        'status': result['status'],
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update customer: ${viewModel.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewCustomerDetails(Customer customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View ${customer.name} details coming soon!')),
    );
  }

  void _deleteCustomer(Customer customer) {
    final viewModel = Provider.of<CustomerViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete ${customer.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await viewModel.deleteCustomer(customer.id);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${customer.name} has been deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete customer: ${viewModel.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Manage Customers'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNewCustomer,
                tooltip: 'Add New Customer',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.refresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${viewModel.error}',
                            style: AppTextStyles.body.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Retry',
                            onPressed: viewModel.refresh,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Search and Filter Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Search Bar
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search customers...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: viewModel.updateSearchQuery,
                              ),
                              const SizedBox(height: 16),
                              
                              // Filters Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Type: ', style: AppTextStyles.caption),
                                        DropdownButton<String>(
                                          value: viewModel.typeFilter,
                                          isExpanded: true,
                                          items: ['All', 'Premium', 'Standard']
                                              .map((type) => DropdownMenuItem(
                                                    value: type,
                                                    child: Text(type),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              viewModel.updateTypeFilter(value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ', style: AppTextStyles.caption),
                                        DropdownButton<String>(
                                          value: viewModel.statusFilter,
                                          isExpanded: true,
                                          items: ['All', 'Active', 'Inactive']
                                              .map((status) => DropdownMenuItem(
                                                    value: status,
                                                    child: Text(status),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              viewModel.updateStatusFilter(value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Statistics Cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppCard(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${viewModel.totalCustomers}',
                                        style: AppTextStyles.headline.copyWith(color: AppColors.primary),
                                      ),
                                      Text('Total Customers', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppCard(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${viewModel.premiumCustomers}',
                                        style: AppTextStyles.headline.copyWith(color: Colors.purple),
                                      ),
                                      Text('Premium', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppCard(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${viewModel.activeCustomers}',
                                        style: AppTextStyles.headline.copyWith(color: Colors.green),
                                      ),
                                      Text('Active', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Customers List
                        Expanded(
                          child: viewModel.filteredCustomers.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No customers found',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  itemCount: viewModel.filteredCustomers.length,
                                  itemBuilder: (context, index) {
                                    final customer = viewModel.filteredCustomers[index];
                                    return AppCard(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary,
                                          child: const Icon(Icons.business, color: Colors.white),
                                        ),
                                        title: Text(customer.name, style: AppTextStyles.subtitle),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(customer.email),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getTypeColor(customer.serviceTypeDisplay),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    customer.serviceTypeDisplay,
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(customer.statusDisplay),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    customer.statusDisplay,
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('${customer.poolsCount} pools'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Next service: ${customer.nextService}',
                                              style: AppTextStyles.caption.copyWith(color: Colors.orange),
                                            ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'view':
                                                _viewCustomerDetails(customer);
                                                break;
                                              case 'edit':
                                                _editCustomer(customer);
                                                break;
                                              case 'delete':
                                                _deleteCustomer(customer);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'view',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility),
                                                  SizedBox(width: 8),
                                                  Text('View Details'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNewCustomer,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
} 