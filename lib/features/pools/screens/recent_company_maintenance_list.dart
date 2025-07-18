import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../services/pool_service.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'maintenance_details_screen.dart';

class RecentCompanyMaintenanceList extends StatefulWidget {
  const RecentCompanyMaintenanceList({Key? key}) : super(key: key);

  @override
  State<RecentCompanyMaintenanceList> createState() => _RecentCompanyMaintenanceListState();
}

class _RecentCompanyMaintenanceListState extends State<RecentCompanyMaintenanceList> {
  String? _selectedPoolId;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _companyPools = [];
  List<Map<String, dynamic>> _companyMaintenances = [];
  bool _poolsLoaded = false;
  bool _maintenancesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_poolsLoaded) {
      _loadCompanyPools();
    }
    if (!_maintenancesLoaded) {
      _loadCompanyMaintenances();
    }
  }

  Future<void> _loadCompanyPools() async {
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final companyId = authService.currentUser?.companyId;

    if (companyId != null) {
      try {
      final pools = await poolService.getCompanyPools(companyId);
        
      if (mounted) {
        setState(() {
          _companyPools = pools;
          _poolsLoaded = true;
        });
      }
      } catch (e) {
        debugPrint('Error loading company pools: $e');
        if (mounted) {
          setState(() {
            _companyPools = [];
            _poolsLoaded = true;
          });
        }
      }
    }
  }

  Future<void> _loadCompanyMaintenances() async {
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final companyId = authService.currentUser?.companyId;

    if (companyId != null) {
      try {
        // Get all maintenance records for this company
        final maintenancesQuery = await FirebaseFirestore.instance
            .collection('pool_maintenances')
            .where('companyId', isEqualTo: companyId)
            .orderBy('date', descending: true)
            .limit(200) // Get last 200 maintenance records
            .get();
        
        final maintenances = maintenancesQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'poolId': data['poolId'],
            'poolName': data['poolName'],
            'poolAddress': data['poolAddress'] ?? data['address'],
            'date': data['date'],
            'status': data['status'],
            ...data,
          };
        }).toList();
        

        
        if (mounted) {
          setState(() {
            _companyMaintenances = maintenances;
            _maintenancesLoaded = true;
          });
        }
      } catch (e) {
        debugPrint('Error loading company maintenances: $e');
        if (mounted) {
          setState(() {
            _companyMaintenances = [];
            _maintenancesLoaded = true;
          });
        }
      }
    }
  }

  // Get unique pool addresses from maintenance records
  List<Map<String, dynamic>> _getUniquePoolsFromMaintenances() {
    final Map<String, Map<String, dynamic>> uniquePools = {};
    
    for (var maintenance in _companyMaintenances) {
      final poolId = maintenance['poolId'];
      if (poolId != null && !uniquePools.containsKey(poolId)) {
        uniquePools[poolId] = {
          'poolId': poolId,
          'poolName': maintenance['poolName'],
          'poolAddress': maintenance['poolAddress'],
        };
      }
    }
    
    return uniquePools.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final companyId = authService.currentUser?.companyId;
    if (companyId == null) {
      return const AppCard(child: Text('Not part of a company.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text('Recent Maintenance (Last 20)', style: AppTextStyles.headline),
        ),
        _buildFilters(),
        StreamBuilder<QuerySnapshot>(
          stream: poolService.streamRecentCompanyMaintenances(
            companyId: companyId,
            poolId: _selectedPoolId,
            status: _selectedStatus,
            startDate: _startDate,
            endDate: _endDate,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No recent maintenance records found.'),
              );
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildDetailedMaintenanceCard(data, docs[index].id);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedMaintenanceCard(Map<String, dynamic> data, String maintenanceId) {
    final date = (data['date'] as Timestamp?)?.toDate();
    final address = data['poolAddress'] ?? data['address'] ?? 'Unknown address';
    final status = data['status'] ?? 'Unknown';
    final poolName = data['poolName'] ?? 'Pool';
    final workerName = data['performedByName'] ?? 'N/A';
    final cost = data['cost'] ?? 0.0;
    final notes = data['notes'] ?? '';
    final nextMaintenanceDate = (data['nextMaintenanceDate'] as Timestamp?)?.toDate();
    
    // Extract chemical and physical data
    final standardChemicals = data['standardChemicals'] as Map<String, dynamic>? ?? {};
    final detailedChemicals = data['detailedChemicals'] as Map<String, dynamic>? ?? {};
    final standardPhysical = data['standardPhysical'] as Map<String, dynamic>? ?? {};
    final detailedPhysical = data['detailedPhysical'] as Map<String, dynamic>? ?? {};
    final waterQuality = data['waterQuality'] as Map<String, dynamic>? ?? {};

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MaintenanceDetailsScreen(
              maintenanceId: maintenanceId,
              maintenanceData: data,
            ),
          ),
        );
      },
      child: AppCard(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with basic info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.build_circle,
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
                        poolName,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      if (data['poolType'] != null && data['poolType'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 80, minHeight: 28),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              data['poolType'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ),
                      ),
                      Text(
                        address,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      // Remove the type chip from the row with the calendar icon below
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            date != null ? '${date.toLocal().toString().split(' ')[0]}' : 'No date',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (cost > 0)
                      Text(
                        '\$${cost.toStringAsFixed(2)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Date and worker info
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  workerName,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            
            // Chemical usage summary
            if (_hasChemicalData(standardChemicals, detailedChemicals)) ...[
              const SizedBox(height: 12),
              _buildChemicalSummary(standardChemicals, detailedChemicals),
            ],
            
            // Physical maintenance summary
            if (_hasPhysicalData(standardPhysical, detailedPhysical)) ...[
              const SizedBox(height: 8),
              _buildPhysicalSummary(standardPhysical, detailedPhysical),
            ],
            
            // Water quality metrics
            if (_hasWaterQualityData(waterQuality)) ...[
              const SizedBox(height: 8),
              _buildWaterQualitySummary(waterQuality),
            ],
            
            // Next maintenance date
            if (nextMaintenanceDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Next: ${nextMaintenanceDate.toLocal().toString().split(' ')[0]}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            
            // Notes preview
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(107, 114, 128, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notes.length > 100 ? '${notes.substring(0, 100)}...' : notes,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap for details',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalSummary(Map<String, dynamic> standardChemicals, Map<String, dynamic> detailedChemicals) {
    final List<String> chemicals = [];
    
    // Standard chemicals
    if (standardChemicals['chlorineLiquidGallons'] != null && standardChemicals['chlorineLiquidGallons'] > 0) {
      chemicals.add('Chlorine: ${standardChemicals['chlorineLiquidGallons']} gal');
    }
    if (standardChemicals['chlorineTablets'] != null && standardChemicals['chlorineTablets'] > 0) {
      chemicals.add('Tablets: ${standardChemicals['chlorineTablets']}');
    }
    if (standardChemicals['muriaticAcidGallons'] != null && standardChemicals['muriaticAcidGallons'] > 0) {
      chemicals.add('Muriatic Acid: ${standardChemicals['muriaticAcidGallons']} gal');
    }
    if (standardChemicals['algaecideUsed'] == true) {
      chemicals.add('Algaecide');
    }
    
    // Detailed chemicals
    if (detailedChemicals['calciumHypochloriteLbs'] != null && detailedChemicals['calciumHypochloriteLbs'] > 0) {
      chemicals.add('Cal-Hypo: ${detailedChemicals['calciumHypochloriteLbs']} lbs');
    }
    if (detailedChemicals['copperAlgaecideUsed'] == true) {
      chemicals.add('Copper Algaecide');
    }
    if (detailedChemicals['polyquatAlgaecideUsed'] == true) {
      chemicals.add('Polyquat Algaecide');
    }
    if (detailedChemicals['chelatingUsed'] == true) {
      chemicals.add('Chelating Agent');
    }
    if (detailedChemicals['poolClarifierUsed'] == true) {
      chemicals.add('Clarifier');
    }
    
    if (chemicals.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Chemicals Used',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: chemicals.take(3).map((chemical) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color.fromRGBO(59, 130, 246, 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chemical,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            )).toList(),
          ),
          if (chemicals.length > 3)
            Text(
              '+${chemicals.length - 3} more',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhysicalSummary(Map<String, dynamic> standardPhysical, Map<String, dynamic> detailedPhysical) {
    final List<String> physical = [];
    
    // Standard physical
    if (standardPhysical['wallBrushUsed'] == true) {
      physical.add('Wall Brush');
    }
    if (standardPhysical['cartridgeFilterCleanerUsed'] == true) {
      physical.add('Filter Cleaner');
    }
    if (standardPhysical['poolFilterCleanUpUsed'] == true) {
      physical.add('Filter Cleanup');
    }
    
    // Detailed physical
    if (detailedPhysical['poolPump']?['cleanUp'] == true) {
      physical.add('Pump Cleanup');
    }
    if (detailedPhysical['saltSystem']?['cleanUp'] == true) {
      physical.add('Salt System');
    }
    if (detailedPhysical['filterCleaners']?['sandFilterClean'] == true) {
      physical.add('Sand Filter');
    }
    
    // Check for any costs
    double totalCost = 0;
    if (detailedPhysical['poolFilter']?['installCost'] != null) {
      totalCost += detailedPhysical['poolFilter']['installCost'];
    }
    if (detailedPhysical['poolFilter']?['replaceCost'] != null) {
      totalCost += detailedPhysical['poolFilter']['replaceCost'];
    }
    if (detailedPhysical['poolPump']?['installCost'] != null) {
      totalCost += detailedPhysical['poolPump']['installCost'];
    }
    if (detailedPhysical['poolPump']?['replaceCost'] != null) {
      totalCost += detailedPhysical['poolPump']['replaceCost'];
    }
    if (detailedPhysical['poolPump']?['repairCost'] != null) {
      totalCost += detailedPhysical['poolPump']['repairCost'];
    }
    
    if (physical.isEmpty && totalCost == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(16, 185, 129, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(16, 185, 129, 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                'Physical Work',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (totalCost > 0) ...[
                const Spacer(),
                Text(
                  'Cost: \$${totalCost.toStringAsFixed(2)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (physical.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: physical.take(3).map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(16, 185, 129, 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontSize: 10,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterQualitySummary(Map<String, dynamic> waterQuality) {
    final List<String> metrics = [];
    
    if (waterQuality['ph'] != null) {
      metrics.add('pH: ${waterQuality['ph']}');
    }
    if (waterQuality['chlorine'] != null) {
      metrics.add('Cl: ${waterQuality['chlorine']} ppm');
    }
    if (waterQuality['alkalinity'] != null) {
      metrics.add('Alk: ${waterQuality['alkalinity']} ppm');
    }
    if (waterQuality['calcium'] != null) {
      metrics.add('Ca: ${waterQuality['calcium']} ppm');
    }
    
    if (metrics.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(34, 197, 94, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(34, 197, 94, 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Water Quality',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: metrics.map((metric) => Text(
              metric,
              style: AppTextStyles.caption.copyWith(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            )).toList(),
          ),
        ],
      ),
    );
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

  Widget _buildFilters() {
    final statusOptions = ['Completed', 'In Progress', 'Scheduled', 'Cancelled'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First line: Pool search input (full width)
          Row(
            children: [
          Expanded(
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.trim().isEmpty) {
                  return _companyPools;
                }
                final searchText = textEditingValue.text.toLowerCase();
                return _companyPools.where((pool) {
                  final name = (pool['name'] ?? '').toString().toLowerCase();
                  final address = (pool['address'] ?? '').toString().toLowerCase();
                  return name.contains(searchText) || address.contains(searchText);
                });
              },
              displayStringForOption: (option) =>
                (option['name'] ?? '') + (option['address'] != null ? ' - ' + option['address'] : ''),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search by pool address or name',
                    hintStyle: TextStyle(
                      color: Color.fromRGBO(107, 114, 128, 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
              onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _selectedPoolId = null;
                      });
                    }
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.white,
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 350,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final name = option['name'] ?? '';
                          final address = option['address'] ?? '';
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (name.isNotEmpty)
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (option) {
                setState(() {
                  _selectedPoolId = option['id'];
                });
              },
            ),
          ),
            ],
          ),
          const SizedBox(height: 10),
          // Second line: Status dropdown and date filter (side by side)
          Row(
            children: [
              // Status filter (dropdown)
              Expanded(
            child: Container(
                  height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              underline: SizedBox(),
                    value: _selectedStatus,
                    hint: Text(
                      'Status',
                      style: TextStyle(
                        color: Color.fromRGBO(107, 114, 128, 0.7),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Date filter (icon button)
          SizedBox(
            height: 40,
            width: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                      firstDate: DateTime(2022, 1, 1),
                      lastDate: DateTime.now(),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
              }
            },
              child: const Icon(Icons.calendar_today, color: Colors.blue, size: 22),
            ),
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20, color: Colors.redAccent),
              tooltip: 'Clear date',
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
                ),
            ],
            ),
        ],
      ),
    );
  }
} 