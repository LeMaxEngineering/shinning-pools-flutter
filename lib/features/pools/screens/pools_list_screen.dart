import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/role.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../services/pool_service.dart';
import 'pool_form_screen.dart';
import 'pool_details_screen.dart';

class PoolsListScreen extends StatefulWidget {
  final String? customerId;
  const PoolsListScreen({super.key, this.customerId});

  @override
  State<PoolsListScreen> createState() => _PoolsListScreenState();
}

class _PoolsListScreenState extends State<PoolsListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _typeFilter = 'All';
  String _customerFilter = 'All';
  bool _showSearchBar = false;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePoolsData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializePoolsData() {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.companyId != null && !_isInitialized) {
      final poolService = context.read<PoolService>();
      poolService.initializePoolsStream(currentUser!.companyId!);
      setState(() {
        _isInitialized = true;
      });
    }
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
      
      final matchesStatus = _statusFilter == 'All' || pool['status']?.toString().toLowerCase() == _statusFilter.toLowerCase();
      final matchesType = _typeFilter == 'All' || (pool['specifications']?['type'] == _typeFilter);
      final matchesCustomer = _customerFilter == 'All' || (pool['customerName'] == _customerFilter);
      final matchesCustomerId = widget.customerId == null || pool['customerId'] == widget.customerId;
      
      return matchesSearch && matchesStatus && matchesType && matchesCustomer && matchesCustomerId;
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
    switch (quality.toLowerCase()) {
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
    if (currentUser == null || currentUser.companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No company information found.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PoolFormScreen()),
    );
    
    // Pool creation is now handled inside PoolFormScreen
    // result is just a boolean indicating success
    if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pool created successfully!'),
          backgroundColor: Colors.green,
          ),
        );
    }
  }

  void _editPool(Map<String, dynamic> pool) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolFormScreen(pool: pool)),
    );
    
    // Pool update/delete is now handled inside PoolFormScreen
    // result is just a boolean indicating success
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pool updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewPoolDetails(Map<String, dynamic> pool) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolDetailsScreen(poolId: pool['id'])),
    );
  }

  void _deletePool(Map<String, dynamic> pool) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pool'),
          content: Text('Are you sure you want to delete ${pool['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final poolService = context.read<PoolService>();
      final success = await poolService.deletePool(pool['id']);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pool['name']} has been deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete pool: ${poolService.error ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final poolService = context.watch<PoolService>();
    final currentUser = authService.currentUser;

    // Initialize data if not done yet
    if (currentUser?.companyId != null && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePoolsData();
      });
    }

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
                      AppColors.textPrimary.red,
                      AppColors.textPrimary.green,
                      AppColors.textPrimary.blue,
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
            : const Text('Pools Management'),
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
          : _buildBody(poolService),
      floatingActionButton: currentUser?.role == UserRole.admin
          ? FloatingActionButton(
              onPressed: _addNewPool,
              child: const Icon(Icons.add),
              tooltip: 'Add New Pool',
            )
          : null,
    );
  }

  Widget _buildBody(PoolService poolService) {
    if (poolService.isLoading && poolService.pools.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

    if (poolService.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${poolService.error}', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                });
                _initializePoolsData();
              },
            ),
          ],
        ),
      );
    }

    final filteredPools = _filteredPools;

    if (filteredPools.isEmpty && poolService.pools.isEmpty) {
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

    if (filteredPools.isEmpty && poolService.pools.isNotEmpty) {
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
                                  dropdownColor: AppColors.primary,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                  value: _statusFilter,
                                  isExpanded: true,
                                  items: ['All', 'active', 'maintenance', 'closed', 'inactive']
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status == 'All' ? 'All' : (status[0].toUpperCase() + status.substring(1))),
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
                                  dropdownColor: AppColors.primary,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
                dropdownColor: AppColors.primary,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
          radius: 30,
          child: ClipOval(
            child: pool['photoUrl'] != null && pool['photoUrl'].toString().isNotEmpty
                ? _buildPoolImage(pool['photoUrl'])
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.primary,
                    child: const Icon(
                      Icons.pool,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
          ),
        ),
        title: Text(pool['name'] ?? 'Unnamed Pool', style: AppTextStyles.subtitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pool['address'] ?? 'No address', style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            // New line for type chip and calendar icon
            Row(
              children: [
                if (pool['specifications'] != null && pool['specifications']['type'] != null) ...[
                  SizedBox(
                    width: 100,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        (pool['specifications']['type'] ?? '').toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  pool['nextMaintenanceDate'] != null ? pool['nextMaintenanceDate'].toString() : 'No date',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pool['status'] ?? 'unknown'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (pool['status'] ?? 'unknown').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (pool['waterQualityMetrics'] != null) ...[
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getWaterQualityColor(pool['waterQualityMetrics']['quality'] ?? 'unknown'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (pool['waterQualityMetrics']['quality'] ?? 'unknown').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    '${pool['size']?.toString() ?? 'Unknown'} m²',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Next maintenance: ${pool['nextMaintenanceDate'] ?? 'Not scheduled'}',
              style: AppTextStyles.caption.copyWith(color: Colors.orange),
              overflow: TextOverflow.ellipsis,
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
                mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
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
                mainAxisSize: MainAxisSize.min,
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

  Widget _buildPoolImage(String photoUrl) {
    // Handle data URLs (base64 encoded images)
    if (photoUrl.startsWith('data:image/')) {
      final base64Data = photoUrl.split(',')[1];
      final bytes = base64Decode(base64Data);
      
      return Image.memory(
        bytes,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: AppColors.primary,
            child: const Icon(
              Icons.pool,
              color: Colors.white,
              size: 30,
            ),
          );
        },
      );
    }
    
    // Handle network URLs (Firebase Storage)
    return Image.network(
      photoUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          color: AppColors.primary,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: AppColors.primary,
          child: const Icon(
            Icons.pool,
            color: Colors.white,
            size: 30,
          ),
        );
      },
    );
  }
} 