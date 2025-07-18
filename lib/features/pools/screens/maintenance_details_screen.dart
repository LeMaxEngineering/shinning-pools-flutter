import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../services/pool_service.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/theme/colors.dart';
import 'maintenance_form_screen.dart';

class MaintenanceDetailsScreen extends StatefulWidget {
  final String maintenanceId;
  final Map<String, dynamic> maintenanceData;

  const MaintenanceDetailsScreen({
    Key? key,
    required this.maintenanceId,
    required this.maintenanceData,
  }) : super(key: key);

  @override
  State<MaintenanceDetailsScreen> createState() => _MaintenanceDetailsScreenState();
}

class _MaintenanceDetailsScreenState extends State<MaintenanceDetailsScreen> {
  bool _isLoading = false;
  bool _canEdit = false;
  bool _checkedPermissions = false;
  String? _poolAddress;

  @override
  void initState() {
    super.initState();
    _checkEditPermissionsAndPoolAddress();
  }

  Future<void> _checkEditPermissionsAndPoolAddress() async {
    final data = widget.maintenanceData;
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final currentUser = authService.currentUser;
    String? poolAddress;
    if (currentUser == null) {
      setState(() {
        _canEdit = false;
        _checkedPermissions = true;
        _poolAddress = null;
      });
      return;
    }
    final userCompanyId = currentUser.companyId;
    final maintenanceCompanyId = data['companyId'];
    final poolId = data['poolId'];
    // Extract role properly - handle both enum and string cases
    String userRole;
    if (currentUser.role == null) {
      userRole = '';
    } else {
      // Convert to string and extract the actual role value
      final roleString = currentUser.role.toString();
      userRole = roleString.contains('.') 
          ? roleString.split('.').last.toLowerCase()
          : roleString.toLowerCase();
    }
    if (poolId == null) {
      setState(() {
        _canEdit = false;
        _checkedPermissions = true;
        _poolAddress = null;
      });
      return;
    }
    final pool = await poolService.getPool(poolId);
    final poolCompanyId = pool != null ? pool['companyId'] : null;
    poolAddress = pool != null && pool['address'] != null && pool['address'].toString().isNotEmpty
      ? pool['address']
      : (data['address'] ?? 'Unknown address');
    bool canEdit = false;
    if (userRole == 'root') {
      canEdit = true;
    } else if ((userRole == 'company_admin' || userRole == 'admin') &&
        userCompanyId == maintenanceCompanyId &&
        userCompanyId == poolCompanyId) {
      canEdit = true;
    } else if (userRole == 'worker' &&
        currentUser.id == data['performedBy'] &&
        userCompanyId == maintenanceCompanyId &&
        userCompanyId == poolCompanyId) {
      canEdit = true;
    }
    setState(() {
      _canEdit = canEdit;
      _checkedPermissions = true;
      _poolAddress = poolAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.maintenanceData;
    final date = (data['date'] as Timestamp?)?.toDate();
    final address = data['poolAddress'] ?? data['address'] ?? 'Unknown address';
    final status = data['status'] ?? 'Unknown';
    final poolName = data['poolName'] ?? 'Pool';
    final workerName = data['performedByName'] ?? 'N/A';
    final cost = data['cost'] ?? 0.0;
    final notes = data['notes'] ?? '';
    final nextMaintenanceDate = (data['nextMaintenanceDate'] as Timestamp?)?.toDate();
    final technician = data['technician'] ?? '';
    
    // Extract chemical and physical data
    final standardChemicals = data['standardChemicals'] as Map<String, dynamic>? ?? {};
    final detailedChemicals = data['detailedChemicals'] as Map<String, dynamic>? ?? {};
    final standardPhysical = data['standardPhysical'] as Map<String, dynamic>? ?? {};
    final detailedPhysical = data['detailedPhysical'] as Map<String, dynamic>? ?? {};
    final waterQuality = data['waterQuality'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Maintenance Details',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_checkedPermissions)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            ),
          if (_checkedPermissions && _canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _editMaintenance(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.build_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poolName,
                              style: AppTextStyles.headline.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _poolAddress ?? 'Unknown address',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(59, 130, 246, 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cost > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Cost',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              '\$${cost.toStringAsFixed(2)}',
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Information', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow('Date', date != null ? '${date.toLocal().toString().split(' ')[0]}' : 'Not specified'),
                  _buildInfoRow('Performed by', workerName),
                  if (technician.isNotEmpty) _buildInfoRow('Technician', technician),
                  if (nextMaintenanceDate != null) 
                    _buildInfoRow('Next Maintenance', '${nextMaintenanceDate.toLocal().toString().split(' ')[0]}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chemical Maintenance
            if (_hasChemicalData(standardChemicals, detailedChemicals)) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Text('Chemical Maintenance', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildChemicalDetails(standardChemicals, detailedChemicals),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Physical Maintenance
            if (_hasPhysicalData(standardPhysical, detailedPhysical)) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build, color: AppColors.secondary, size: 24),
                        const SizedBox(width: 8),
                        Text('Physical Maintenance', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPhysicalDetails(standardPhysical, detailedPhysical),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Water Quality
            if (_hasWaterQualityData(waterQuality)) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Text('Water Quality Metrics', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildWaterQualityDetails(waterQuality),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (notes.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, color: AppColors.textSecondary, size: 24),
                        const SizedBox(width: 8),
                        Text('Notes', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(107, 114, 128, 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color.fromRGBO(107, 114, 128, 0.2)),
                      ),
                      child: Text(
                        notes,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (_checkedPermissions && _canEdit) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Maintenance',
                      onPressed: _editMaintenance,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: 'Delete',
                      onPressed: _deleteMaintenance,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Widget _buildChemicalDetails(Map<String, dynamic> standardChemicals, Map<String, dynamic> detailedChemicals) {
    final List<Widget> chemicalItems = [];

    // Standard chemicals
    if (standardChemicals['chlorineLiquidGallons'] != null && standardChemicals['chlorineLiquidGallons'] > 0) {
      chemicalItems.add(_buildChemicalItem('Chlorine Liquid', '${standardChemicals['chlorineLiquidGallons']} gallons'));
    }
    if (standardChemicals['chlorineTablets'] != null && standardChemicals['chlorineTablets'] > 0) {
      chemicalItems.add(_buildChemicalItem('Chlorine Tablets', '${standardChemicals['chlorineTablets']} tablets'));
    }
    if (standardChemicals['muriaticAcidGallons'] != null && standardChemicals['muriaticAcidGallons'] > 0) {
      chemicalItems.add(_buildChemicalItem('Muriatic Acid', '${standardChemicals['muriaticAcidGallons']} gallons'));
    }
    if (standardChemicals['algaecideUsed'] == true) {
      chemicalItems.add(_buildChemicalItem('Algaecide', 'Used'));
    }

    // Show all detailed chemicals present in the map
    detailedChemicals.forEach((key, value) {
      if (value != null && value != false && value != 0 && value.toString().isNotEmpty) {
        String label = _prettifyKey(key);
        String displayValue = value is bool ? (value ? 'Used' : 'Not used') : value.toString();
        chemicalItems.add(_buildChemicalItem(label, displayValue));
      }
    });

    return Column(
      children: chemicalItems,
    );
  }

  Widget _buildChemicalItem(String name, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalDetails(Map<String, dynamic> standardPhysical, Map<String, dynamic> detailedPhysical) {
    final List<Widget> physicalItems = [];

    // Standard physical
    if (standardPhysical['wallBrushUsed'] == true) {
      physicalItems.add(_buildPhysicalItem('Wall Brush & Vacuum', 'Completed'));
    }
    if (standardPhysical['cartridgeFilterCleanerUsed'] == true) {
      physicalItems.add(_buildPhysicalItem('Cartridge Filter Cleaner', 'Used'));
    }
    if (standardPhysical['poolFilterCleanUpUsed'] == true) {
      physicalItems.add(_buildPhysicalItem('Pool Filter Cleanup', 'Completed'));
    }

    // Show all detailed physical present in the map (flatten nested maps)
    void addPhysicalDetails(String prefix, dynamic map) {
      if (map is Map) {
        map.forEach((k, v) => addPhysicalDetails(prefix.isEmpty ? k : '$prefix > $k', v));
      } else if (map != null && map != false && map != 0 && map.toString().isNotEmpty) {
        String label = _prettifyKey(prefix);
        String displayValue = map is bool ? (map ? 'Completed' : 'Not completed') : map.toString();
        physicalItems.add(_buildPhysicalItem(label, displayValue));
      }
    }
    addPhysicalDetails('', detailedPhysical);

    return Column(
      children: physicalItems,
    );
  }

  Widget _buildPhysicalItem(String name, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(16, 185, 129, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(16, 185, 129, 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.build, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterQualityDetails(Map<String, dynamic> waterQuality) {
    final List<Widget> qualityItems = [];

    if (waterQuality['ph'] != null) {
      qualityItems.add(_buildQualityItem('pH Level', '${waterQuality['ph']}', _getPhColor(waterQuality['ph'])));
    }
    if (waterQuality['chlorine'] != null) {
      qualityItems.add(_buildQualityItem('Chlorine', '${waterQuality['chlorine']} ppm', _getChlorineColor(waterQuality['chlorine'])));
    }
    if (waterQuality['alkalinity'] != null) {
      qualityItems.add(_buildQualityItem('Total Alkalinity', '${waterQuality['alkalinity']} ppm', _getAlkalinityColor(waterQuality['alkalinity'])));
    }
    if (waterQuality['calcium'] != null) {
      qualityItems.add(_buildQualityItem('Calcium Hardness', '${waterQuality['calcium']} ppm', _getCalciumColor(waterQuality['calcium'])));
    }

    return Column(
      children: qualityItems,
    );
  }

  Widget _buildQualityItem(String name, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhColor(double ph) {
    if (ph >= 7.2 && ph <= 7.6) return Colors.green;
    if (ph >= 7.0 && ph <= 7.8) return Colors.orange;
    return Colors.red;
  }

  Color _getChlorineColor(double chlorine) {
    if (chlorine >= 1.0 && chlorine <= 3.0) return Colors.green;
    if (chlorine >= 0.5 && chlorine <= 4.0) return Colors.orange;
    return Colors.red;
  }

  Color _getAlkalinityColor(double alkalinity) {
    if (alkalinity >= 80 && alkalinity <= 120) return Colors.green;
    if (alkalinity >= 60 && alkalinity <= 180) return Colors.orange;
    return Colors.red;
  }

  Color _getCalciumColor(double calcium) {
    if (calcium >= 200 && calcium <= 400) return Colors.green;
    if (calcium >= 150 && calcium <= 500) return Colors.orange;
    return Colors.red;
  }

  bool _hasChemicalData(Map<String, dynamic> standardChemicals, Map<String, dynamic> detailedChemicals) {
    return standardChemicals.isNotEmpty || detailedChemicals.isNotEmpty;
  }

  bool _hasPhysicalData(Map<String, dynamic> standardPhysical, Map<String, dynamic> detailedPhysical) {
    return standardPhysical.isNotEmpty || detailedPhysical.isNotEmpty;
  }

  bool _hasWaterQualityData(Map<String, dynamic> waterQuality) {
    return waterQuality.isNotEmpty && (
      waterQuality['ph'] != null ||
      waterQuality['chlorine'] != null ||
      waterQuality['alkalinity'] != null ||
      waterQuality['calcium'] != null
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _editMaintenance() {
    // Ensure the record has an 'id' field
    final record = Map<String, dynamic>.from(widget.maintenanceData);
    if (!record.containsKey('id') && widget.maintenanceId.isNotEmpty) {
      record['id'] = widget.maintenanceId;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          maintenanceRecord: record,
        ),
      ),
    );
  }

  void _deleteMaintenance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Maintenance Record'),
        content: const Text('Are you sure you want to delete this maintenance record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    setState(() => _isLoading = true);

    try {
      final poolService = context.read<PoolService>();
      await poolService.deleteMaintenanceRecord(widget.maintenanceId);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting maintenance record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _prettifyKey(String key) {
    // Convert camelCase or snake_case to Title Case for display
    String result = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
                       .replaceAll('_', ' ')
                       .replaceAll(' > ', ' / ')
                       .trim();
    
    // Capitalize first letter
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    
    return result;
  }
} 