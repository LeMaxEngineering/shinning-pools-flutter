import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/pool_location_map.dart';
import '../../../shared/ui/widgets/simple_pool_map.dart';
import '../../../shared/ui/widgets/location_display_widget.dart';
import '../../../core/services/customer_repository.dart';
import '../../../features/customers/models/customer.dart';
import 'pool_form_screen.dart';
import 'maintenance_form_screen.dart';

class PoolDetailsScreen extends StatefulWidget {
  final String poolId;

  const PoolDetailsScreen({
    Key? key,
    required this.poolId,
  }) : super(key: key);

  @override
  State<PoolDetailsScreen> createState() => _PoolDetailsScreenState();
}

class _PoolDetailsScreenState extends State<PoolDetailsScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  Customer? _customer;
  bool _loadingCustomer = false;
  String? _customerError;

  Future<void> _loadCustomerInfo(String customerId) async {
    if (!mounted) return;
    setState(() { _loadingCustomer = true; });
    try {
      final customer = await _customerRepository.getCustomer(customerId);
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _loadingCustomer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _customerError = e.toString();
        _loadingCustomer = false;
      });
    }
  }

  Future<void> _openInMaps(String address) async {
    if (address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No address available for navigation')),
      );
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);
    final urls = [
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress', // Google Maps Web
      'geo:0,0?q=$encodedAddress', // Android Maps
      'maps:0,0?q=$encodedAddress', // iOS Maps
    ];

    bool launched = false;
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps application')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('pools').doc(widget.poolId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pool not found.')),
          );
        }

        final pool = snapshot.data!.data() as Map<String, dynamic>;
        // Add the document ID to the map for convenience
        pool['id'] = snapshot.data!.id;

        // Load customer info if we have a customer ID and haven't loaded it yet
        final customerId = pool['customerId'] as String?;
        if (customerId != null && customerId.isNotEmpty && _customer?.id != customerId && !_loadingCustomer) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadCustomerInfo(customerId);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(pool['name'] ?? 'Pool Details'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pool Photo Section
                if (pool['photoUrl'] != null && pool['photoUrl'].toString().isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pool Photo',
                          style: AppTextStyles.headline2,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildPoolDetailImage(pool['photoUrl']),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Pool Location Map Section
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pool Location',
                            style: AppTextStyles.headline2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PoolLocationMap(
                        address: pool['address'] ?? '',
                        poolName: pool['name'] ?? 'Pool',
                        height: 400,
                        interactive: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pool Information',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 16),
                      // Customer Info First
                      if (_customer != null) ...[
                        _buildInfoRow('Customer', _customer!.name),
                        _buildInfoRow('Customer Email', _customer!.email),
                        _buildInfoRow('Customer Phone', _customer!.phone),
                        const Divider(height: 24),
                      ] else if (_loadingCustomer) ...[
                        Row(
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text('Loading customer info...', style: AppTextStyles.caption),
                          ],
                        ),
                        const Divider(height: 24),
                      ] else ...[
                        _buildInfoRow('Customer', 'No customer information'),
                        const Divider(height: 24),
                      ],
                      // Pool Details
                      _buildInfoRow('Name', pool['name'] ?? 'N/A'),
                      _buildInfoRow('Address', pool['address'] ?? 'N/A'),
                      _buildInfoRow('Size', '${pool['size'] ?? 'N/A'} m²'),
                      _buildInfoRow('Status', pool['status'] ?? 'N/A'),
                      _buildInfoRow('Monthly Cost', '\$${pool['monthlyCost'] ?? '0.00'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specifications',
                        style: AppTextStyles.headline2,
                      ),
                      const SizedBox(height: 16),
                      if (pool['specifications'] != null &&
                          (pool['specifications'] as Map).isNotEmpty) ...[
                        for (var entry in (pool['specifications'] as Map<String, dynamic>).entries)
                          _buildInfoRow(_capitalizeLabel(entry.key), _formatSpecificationValue(entry.key, entry.value)),
                      ] else ...[
                        const Text('No specifications available'),
                      ],
                      // Display equipment separately if it exists at root level and not in specifications
                      if (pool['equipment'] != null && (pool['equipment'] as List).isNotEmpty &&
                          !(pool['specifications'] != null && (pool['specifications'] as Map<String, dynamic>).containsKey('equipment'))) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Equipment', _formatEquipment(pool['equipment'])),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maintenance History',
                        style: AppTextStyles.headline2,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MaintenanceFormScreen(
                                    poolId: pool['id'],
                                    poolName: pool['name'] ?? 'Pool',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMaintenanceHistory(pool['maintenanceHistory'] as List?),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PoolFormScreen(pool: pool),
                            ),
                          );
                        },
                        label: 'Edit Pool',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MaintenanceFormScreen(
                                poolId: pool['id'],
                                poolName: pool['name'] ?? 'Pool',
                              ),
                            ),
                          );
                        },
                        label: 'Add Maintenance',
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceHistory(List<dynamic>? maintenanceHistory) {
    if (maintenanceHistory == null || maintenanceHistory.isEmpty) {
      return Column(
        children: [
          const Icon(
            Icons.build_circle_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'No maintenance records yet',
            style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first maintenance record',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
          ),
        ],
      );
    }

    return Column(
      children: [
        ...maintenanceHistory.take(3).map((maintenance) {
          final date = maintenance['date'] is Timestamp 
              ? (maintenance['date'] as Timestamp).toDate()
              : DateTime.now();
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(maintenance['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIcon(maintenance['type']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maintenance['type'] ?? 'Maintenance',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                      ),
                      if (maintenance['performedByName'] != null)
                        Text(
                          'By: ${maintenance['performedByName']}',
                          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(59, 130, 246, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    maintenance['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: _getStatusColor(maintenance['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (maintenanceHistory.length > 3) ...[
          const SizedBox(height: 8),
          Text(
            'and ${maintenanceHistory.length - 3} more records...',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'routine cleaning':
        return Icons.cleaning_services;
      case 'chemical balancing':
        return Icons.science;
      case 'equipment repair':
        return Icons.build;
      case 'filter cleaning':
        return Icons.filter_alt;
      case 'pump maintenance':
        return Icons.water_drop;
      case 'emergency repair':
        return Icons.emergency;
      default:
        return Icons.build_circle;
    }
  }

  String _formatSpecificationValue(String key, dynamic value) {
    if (value is String) {
      return value;
    } else if (value is num) {
      return value.toString();
    } else if (value is Map<String, dynamic>) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    } else if (value is List<dynamic>) {
      return value.map((e) => e.toString()).join('\n');
    } else {
      return 'Unknown format';
    }
  }

  String _formatEquipment(List<dynamic> equipment) {
    return equipment.map((e) => e.toString()).join('\n');
  }

  String _capitalizeLabel(String label) {
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _buildPoolDetailImage(String photoUrl) {
    // Handle data URLs (base64 encoded images)
    if (photoUrl.startsWith('data:image/')) {
      final base64Data = photoUrl.split(',')[1];
      final bytes = base64Decode(base64Data);
      
      return Image.memory(
        bytes,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    
    // Handle network URLs (Firebase Storage)
    return Image.network(
      photoUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
