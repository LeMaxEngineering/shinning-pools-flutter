import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/app_theme.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../models/customer.dart';
import '../viewmodels/customer_viewmodel.dart';
import 'customer_form_screen.dart';
import '../../pools/screens/pools_list_screen.dart';
import '../../pools/services/pool_service.dart';
import '../../../core/services/auth_service.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize PoolService with companyId
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      if (currentUser?.companyId != null) {
        Provider.of<PoolService>(context, listen: false)
            .initializePoolsStream(currentUser!.companyId!);
      }
    });
  }

  ImageProvider? _getCustomerImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    
    if (photoUrl.startsWith('data:image/')) {
      try {
        final base64Data = photoUrl.split(',')[1];
        final bytes = base64Decode(base64Data);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding customer photo data URL: $e');
        return null;
      }
    } else {
      return NetworkImage(photoUrl);
    }
  }

  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'premium':
        return Colors.purple;
      case 'standard':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _editCustomer(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: widget.customer),
      ),
    );

    if (result != null && context.mounted) {
      if (result is Map && result['action'] == 'delete') {
        // Customer was deleted, go back to list
        Navigator.of(context).pop();
      } else {
        // Customer was updated, refresh the screen
        Navigator.of(context).pop('updated');
      }
    }
  }

  void _deleteCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete ${widget.customer.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                final viewModel = Provider.of<CustomerViewModel>(context, listen: false);
                final success = await viewModel.deleteCustomer(widget.customer.id);
                
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.customer.name} has been deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop('deleted'); // Go back to list
                  } else {
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
    final imageProvider = _getCustomerImageProvider(widget.customer.photoUrl);
    final poolService = Provider.of<PoolService>(context);
    final poolsForCustomer = poolService.pools.where((pool) => pool['customerId'] == widget.customer.id).toList();
    final poolsCount = poolsForCustomer.length;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCustomer(context),
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteCustomer(context),
            tooltip: 'Delete Customer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Photo and Basic Info
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.customer.name,
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getServiceTypeColor(widget.customer.serviceTypeDisplay),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.customer.serviceTypeDisplay,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.customer.statusDisplay),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.customer.statusDisplay,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Information', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email', widget.customer.email.isEmpty ? 'Not provided' : widget.customer.email),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, 'Phone', widget.customer.phone),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Address', widget.customer.address),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Service Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Information', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Pools',
                          '$poolsCount',
                          Icons.pool,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Last Service',
                          widget.customer.lastService,
                          Icons.history,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.schedule, 'Next Service', widget.customer.nextService),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account Information', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(widget.customer.createdAt)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.update, 'Last Updated', _formatDate(widget.customer.updatedAt)),
                  if (widget.customer.linkedUserId != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.link, 'Linked User', 'Yes'),
                  ],
                ],
              ),
            ),

            if (widget.customer.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Text(widget.customer.notes, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit Customer',
                    onPressed: () => _editCustomer(context),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'View Pools',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PoolsListScreen(customerId: widget.customer.id),
                        ),
                      );
                    },
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 