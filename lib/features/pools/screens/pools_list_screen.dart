import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';
import 'package:shinning_pools_flutter/core/services/role.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../services/pool_service.dart';
import 'pool_form_screen.dart';
import 'pool_details_screen.dart';

class PoolsListScreen extends StatefulWidget {
  const PoolsListScreen({super.key});

  @override
  State<PoolsListScreen> createState() => _PoolsListScreenState();
}

class _PoolsListScreenState extends State<PoolsListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _typeFilter = 'All';
  String _customerFilter = 'All';
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _showSearchBar = false;
    });
  }

  List<Map<String, dynamic>> get _filteredPools {
    final poolService = context.watch<PoolService>();
    return poolService.pools.where((pool) {
      final matchesSearch = pool['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pool['address'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (pool['customerName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesStatus = _statusFilter == 'All' || pool['status'] == _statusFilter;
      final matchesType = _typeFilter == 'All' || (pool['specifications']?['type'] == _typeFilter);
      final matchesCustomer = _customerFilter == 'All' || (pool['customerName'] == _customerFilter);
      
      return matchesSearch && matchesStatus && matchesType && matchesCustomer;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getWaterQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addNewPool() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser == null || currentUser.companyId == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PoolFormScreen()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      final poolService = context.read<PoolService>();
      
      if (result['action'] == 'delete') {
        return;
      }
      
      await poolService.createPool(
        customerId: result['customerId'] ?? 'mock-customer-id',
        name: result['name'],
        address: result['address'],
        size: result['size'] ?? 0.0,
        specifications: result['specifications'] ?? {},
        status: result['status'] ?? 'active',
        companyId: currentUser.companyId!,
      );
    }
  }

  void _editPool(Map<String, dynamic> pool) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolFormScreen(pool: pool)),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      final poolService = context.read<PoolService>();
      
      if (result['action'] == 'delete') {
        await poolService.deletePool(pool['id']);
        return;
      }
      
      await poolService.updatePool(pool['id'], {
        'name': result['name'],
        'address': result['address'],
        'specifications': result['specifications'] ?? {},
        'status': result['status'] ?? 'active',
      });
    }
  }

  void _viewPoolDetails(Map<String, dynamic> pool) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolDetailsScreen(poolId: pool['id'])),
    );
  }

  void _deletePool(Map<String, dynamic> pool) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pool'),
          content: Text('Are you sure you want to delete ${pool['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final poolService = context.read<PoolService>();
                await poolService.deletePool(pool['id']);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${pool['name']} has been deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

          return Scaffold(
            appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search pools by name, address...',
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(
                      (AppColors.textPrimary.value >> 16) & 0xFF,
                      (AppColors.textPrimary.value >> 8) & 0xFF,
                      AppColors.textPrimary.value & 0xFF,
                      0.8,
                    ),
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('My Pools'),
        actions: [
          _showSearchBar
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: currentUser == null || currentUser.companyId == null
          ? const Center(child: Text('User not associated with a company.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pools')
                  .where('companyId', isEqualTo: currentUser.companyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        const Icon(Icons.pool, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                        Text('No pools found.', style: AppTextStyles.subtitle),
                        const SizedBox(height: 8),
                        const Text('Add a new pool to get started.'),
                      ],
            ),
          );
        }

                final allPools = snapshot.data!.docs
                    .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
                    .toList();

                final filteredPools = allPools.where((pool) {
                  final p = pool as Map<String, dynamic>;
                  final matchesSearch = _searchQuery.isEmpty ||
                      (p['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                      (p['address']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  
                  final matchesStatus = _statusFilter == 'All' || p['status'] == _statusFilter;
                  // final matchesType = _typeFilter == 'All' || (p['specifications']?['type'] == _typeFilter);
                  // final matchesCustomer = _customerFilter == 'All' || (p['customerName'] == _customerFilter);

                  return matchesSearch && matchesStatus;
                }).toList();
                
                if (filteredPools.isEmpty && allPools.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
              children: [
                        const Icon(Icons.search_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No pools match your search.', style: AppTextStyles.subtitle),
                        const SizedBox(height: 8),
                        const Text('Try adjusting your search or filter criteria.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredPools.length,
                  itemBuilder: (context, index) {
                    final pool = filteredPools[index];
                    return _buildPoolCard(pool);
                  },
                );
              },
            ),
      floatingActionButton: currentUser?.role == UserRole.admin
          ? FloatingActionButton(
              onPressed: _addNewPool,
              child: const Icon(Icons.add),
              tooltip: 'Add New Pool',
            )
          : null,
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Pools'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ', style: AppTextStyles.caption),
                                DropdownButton<String>(
                                  value: _statusFilter,
                                  isExpanded: true,
                                  items: ['All', 'active', 'maintenance', 'closed', 'inactive']
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status == 'All' ? 'All' : status.toUpperCase()),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _statusFilter = value!;
                                    });
                                  },
                                ),
              const SizedBox(height: 16),
                                Text('Type: ', style: AppTextStyles.caption),
                                DropdownButton<String>(
                                  value: _typeFilter,
                                  isExpanded: true,
                                  items: ['All', 'Chlorine', 'Salt Water', 'UV', 'Ozone']
                                      .map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _typeFilter = value!;
                                    });
                                  },
                                ),
              const SizedBox(height: 16),
              Text('Customer: ', style: AppTextStyles.caption),
              DropdownButton<String>(
                value: _customerFilter,
                isExpanded: true,
                items: ['All', 'Customer 1', 'Customer 2', 'Customer 3']
                    .map((customer) => DropdownMenuItem(
                          value: customer,
                          child: Text(customer),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _customerFilter = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
                          return AppCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: const Icon(Icons.pool, color: Colors.white),
                              ),
                              title: Text(pool['name'] ?? 'Unnamed Pool', style: AppTextStyles.subtitle),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pool['address'] ?? 'No address'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(pool['status'] ?? 'unknown'),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (pool['status'] ?? 'unknown').toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (pool['waterQualityMetrics'] != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getWaterQualityColor(pool['waterQualityMetrics']['quality'] ?? 'unknown'),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            (pool['waterQualityMetrics']['quality'] ?? 'unknown').toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text('${pool['size']?.toString() ?? 'Unknown'} m²'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Next maintenance: ${pool['nextMaintenanceDate'] ?? 'Not scheduled'}',
                                    style: AppTextStyles.caption.copyWith(color: Colors.orange),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _viewPoolDetails(pool);
                                      break;
                                    case 'edit':
                                      _editPool(pool);
                                      break;
                                    case 'delete':
                                      _deletePool(pool);
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
  }
} 