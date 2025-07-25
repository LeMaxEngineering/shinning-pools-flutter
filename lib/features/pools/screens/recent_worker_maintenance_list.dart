import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/services/auth_service.dart';
import '../services/pool_service.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/theme/colors.dart';
import 'maintenance_details_screen.dart';
import 'package:intl/intl.dart';

class RecentWorkerMaintenanceList extends StatefulWidget {
  const RecentWorkerMaintenanceList({Key? key}) : super(key: key);

  @override
  State<RecentWorkerMaintenanceList> createState() =>
      _RecentWorkerMaintenanceListState();
}

class _RecentWorkerMaintenanceListState
    extends State<RecentWorkerMaintenanceList> {
  String? _selectedPoolId;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _workerMaintenances = [];
  bool _maintenancesLoaded = false;
  StreamSubscription<QuerySnapshot>? _maintenanceSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_maintenancesLoaded) {
      _startListeningToMaintenances();
    }
  }

  @override
  void dispose() {
    _maintenanceSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToMaintenances() {
    final authService = context.read<AuthService>();
    final workerId = authService.currentUser?.id;

    if (workerId == null) return;

    // Cancel any existing subscription
    _maintenanceSubscription?.cancel();

    // Get date range for today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(Duration(days: 1));
    final startDate = Timestamp.fromDate(todayStart);
    final endDate = Timestamp.fromDate(todayEnd);

    // Create real-time listener for today's maintenance records
    final query = FirebaseFirestore.instance
        .collection('pool_maintenances')
        .where('performedById', isEqualTo: workerId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThan: endDate)
        .orderBy('date', descending: true);

    _maintenanceSubscription = query.snapshots().listen(
      (snapshot) async {
        await _processMaintenanceSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('Error listening to maintenance records: $error');
      },
    );
  }

  Future<void> _processMaintenanceSnapshot(QuerySnapshot snapshot) async {
    final maintenances = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final poolId = data['poolId'] as String?;

        String? poolAddress;
        String? customerName;

        // Fetch pool information to get customer name
        if (poolId != null) {
          try {
            // Get current user's company ID for filtering
            final authService = context.read<AuthService>();
            final currentUser = authService.currentUser;
            final companyId = currentUser?.companyId;

            if (companyId != null) {
              // Query pools filtered by company ID to respect security rules
              final poolQuery = await FirebaseFirestore.instance
                  .collection('pools')
                  .where('companyId', isEqualTo: companyId)
                  .get();

              // Filter by poolId in memory since we can't use documentId() in where clause
              final poolDoc = poolQuery.docs
                  .where((doc) => doc.id == poolId)
                  .firstOrNull;

              if (poolDoc != null) {
                final poolData = poolDoc.data() as Map<String, dynamic>;
                poolAddress = poolData['address'] as String?;
                final customerEmail = poolData['customerEmail'] as String?;

                // Fetch customer name using customerEmail, also filtered by company
                if (customerEmail != null) {
                  final customerQuery = await FirebaseFirestore.instance
                      .collection('customers')
                      .where('companyId', isEqualTo: companyId)
                      .where('email', isEqualTo: customerEmail)
                      .limit(1)
                      .get();

                  if (customerQuery.docs.isNotEmpty) {
                    final customerData =
                        customerQuery.docs.first.data() as Map<String, dynamic>;
                    customerName = customerData['name'] as String?;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Error fetching pool/customer data for poolId $poolId: $e',
            );
          }
        }

        return <String, dynamic>{
          'id': doc.id,
          'poolId': poolId,
          'poolName': data['poolName'] as String?,
          'poolAddress':
              poolAddress ??
              data['poolAddress'] as String? ??
              data['address'] as String? ??
              'Unknown Address',
          'customerName': customerName ?? 'Unknown Owner',
          'date': data['date'],
          'status': data['status'] as String?,
          ...data,
        };
      }),
    );

    debugPrint(
      'Real-time update: Loaded ${maintenances.length} maintenance records',
    );

    if (mounted) {
      setState(() {
        _workerMaintenances = maintenances.cast<Map<String, dynamic>>();
        _maintenancesLoaded = true;
      });
    }
  }

  // Manual refresh method (kept for backward compatibility)
  Future<void> _loadWorkerMaintenances() async {
    // Restart the real-time listener
    _startListeningToMaintenances();
  }

  // Public method to refresh the list
  void refreshMaintenances() {
    _startListeningToMaintenances();
  }

  // Get unique pool addresses from maintenance records
  List<Map<String, dynamic>> _getUniquePoolsFromMaintenances() {
    final Map<String, Map<String, dynamic>> uniquePools = {};

    for (var maintenance in _workerMaintenances) {
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

  // Get filtered maintenance records
  List<Map<String, dynamic>> _getFilteredMaintenances() {
    List<Map<String, dynamic>> filtered = List.from(_workerMaintenances);

    // Filter by pool ID
    if (_selectedPoolId != null) {
      filtered = filtered
          .where((maintenance) => maintenance['poolId'] == _selectedPoolId)
          .toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered
          .where(
            (maintenance) =>
                maintenance['status']?.toString().toLowerCase() ==
                _selectedStatus!.toLowerCase(),
          )
          .toList();
    }

    // Filter by date range
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((maintenance) {
        final maintenanceDate = (maintenance['date'] as Timestamp?)?.toDate();
        if (maintenanceDate == null) return false;

        if (_startDate != null && maintenanceDate.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && maintenanceDate.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  // Reload data when filters change
  void _reloadData() {
    setState(() {
      _maintenancesLoaded = false;
    });
    _loadWorkerMaintenances();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final poolService = context.read<PoolService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return const AppCard(child: Text('Not authenticated.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text('Today\'s Maintenance', style: AppTextStyles.headline),
        ),
        _buildFilters(context, poolService, currentUser.id),
        // Use the data we fetched with customer information instead of StreamBuilder
        _maintenancesLoaded
            ? _getFilteredMaintenances().isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No recent maintenance records found.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _getFilteredMaintenances().length,
                      itemBuilder: (context, index) {
                        final data = _getFilteredMaintenances()[index];
                        return _buildDetailedMaintenanceCard(data, data['id']);
                      },
                    )
            : const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildDetailedMaintenanceCard(
    Map<String, dynamic> data,
    String maintenanceId,
  ) {
    final date = (data['date'] as Timestamp?)?.toDate();
    final address = data['poolAddress'] ?? data['address'] ?? 'Unknown address';
    final status = data['status'] ?? 'Unknown';
    final customerName = data['customerName'] ?? 'Unknown Owner';
    final workerName = data['performedByName'] ?? 'N/A';
    final notes = data['notes'] ?? '';
    final nextMaintenanceDate = (data['nextMaintenanceDate'] as Timestamp?)
        ?.toDate();
    final standardChemicals =
        data['standardChemicals'] as Map<String, dynamic>? ?? {};
    final detailedChemicals =
        data['detailedChemicals'] as Map<String, dynamic>? ?? {};
    final standardPhysical =
        data['standardPhysical'] as Map<String, dynamic>? ?? {};
    final detailedPhysical =
        data['detailedPhysical'] as Map<String, dynamic>? ?? {};
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
                        address,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        customerName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // New line for type chip and calendar icon
                      Row(
                        children: [
                          if (data['poolType'] != null &&
                              data['poolType'].toString().isNotEmpty) ...[
                            SizedBox(
                              width: 100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
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
                                  data['poolType'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondary,
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
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date != null
                                ? DateFormat('MMMM dd, yyyy').format(date)
                                : 'No date',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  workerName,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (_hasChemicalData(standardChemicals, detailedChemicals)) ...[
              const SizedBox(height: 12),
              _buildChemicalSummary(standardChemicals, detailedChemicals),
            ],
            if (_hasPhysicalData(standardPhysical, detailedPhysical)) ...[
              const SizedBox(height: 8),
              _buildPhysicalSummary(standardPhysical, detailedPhysical),
            ],
            if (_hasWaterQualityData(waterQuality)) ...[
              const SizedBox(height: 8),
              _buildWaterQualitySummary(waterQuality),
            ],
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
                        notes.length > 100
                            ? '${notes.substring(0, 100)}...'
                            : notes,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
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

  bool _hasChemicalData(
    Map<String, dynamic> standardChemicals,
    Map<String, dynamic> detailedChemicals,
  ) {
    return standardChemicals.isNotEmpty || detailedChemicals.isNotEmpty;
  }

  bool _hasPhysicalData(
    Map<String, dynamic> standardPhysical,
    Map<String, dynamic> detailedPhysical,
  ) {
    return standardPhysical.isNotEmpty || detailedPhysical.isNotEmpty;
  }

  bool _hasWaterQualityData(Map<String, dynamic> waterQuality) {
    return waterQuality.isNotEmpty &&
        (waterQuality['ph'] != null ||
            waterQuality['chlorine'] != null ||
            waterQuality['alkalinity'] != null ||
            waterQuality['calcium'] != null);
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

  Widget _buildFilters(
    BuildContext context,
    PoolService poolService,
    String workerId,
  ) {
    final statusOptions = [
      'Completed',
      'In Progress',
      'Scheduled',
      'Cancelled',
    ];
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
                      return _getUniquePoolsFromMaintenances();
                    }
                    final searchText = textEditingValue.text.toLowerCase();
                    return _getUniquePoolsFromMaintenances().where((pool) {
                      final name = (pool['poolName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final address = (pool['poolAddress'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.contains(searchText) ||
                          address.contains(searchText);
                    });
                  },
                  displayStringForOption: (option) =>
                      (option['poolName'] ?? '') +
                      (option['poolAddress'] != null
                          ? ' - ' + option['poolAddress']
                          : ''),
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2.0,
                              ),
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
                              final name = option['poolName'] ?? '';
                              final address = option['poolAddress'] ?? '';
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      _selectedPoolId = option['poolId'];
                    });
                    _reloadData();
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
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
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
                      _reloadData();
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
                      _reloadData();
                    }
                  },
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: const Icon(
                    Icons.clear,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Clear date',
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _reloadData();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalSummary(
    Map<String, dynamic> standardChemicals,
    Map<String, dynamic> detailedChemicals,
  ) {
    final List<String> chemicals = [];
    // Standard chemicals
    if (standardChemicals['chlorineLiquidGallons'] != null &&
        standardChemicals['chlorineLiquidGallons'] > 0) {
      chemicals.add(
        'Chlorine: ${standardChemicals['chlorineLiquidGallons']} gal',
      );
    }
    if (standardChemicals['chlorineTablets'] != null &&
        standardChemicals['chlorineTablets'] > 0) {
      chemicals.add('Tablets: ${standardChemicals['chlorineTablets']}');
    }
    if (standardChemicals['muriaticAcidGallons'] != null &&
        standardChemicals['muriaticAcidGallons'] > 0) {
      chemicals.add(
        'Muriatic Acid: ${standardChemicals['muriaticAcidGallons']} gal',
      );
    }
    if (standardChemicals['algaecideUsed'] == true) {
      chemicals.add('Algaecide');
    }
    // Detailed chemicals
    if (detailedChemicals['calciumHypochloriteLbs'] != null &&
        detailedChemicals['calciumHypochloriteLbs'] > 0) {
      chemicals.add(
        'Cal-Hypo: ${detailedChemicals['calciumHypochloriteLbs']} lbs',
      );
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
            spacing: 8,
            runSpacing: 2,
            children: chemicals
                .map(
                  (chem) => Text(
                    chem,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalSummary(
    Map<String, dynamic> standardPhysical,
    Map<String, dynamic> detailedPhysical,
  ) {
    final List<String> physical = [];
    if (standardPhysical['wallBrush'] == true) {
      physical.add('Wall Brush');
    }
    if (standardPhysical['filterClean'] == true) {
      physical.add('Filter Clean');
    }
    if (standardPhysical['vacuum'] == true) {
      physical.add('Vacuum');
    }
    if (standardPhysical['skimmerBasket'] == true) {
      physical.add('Skimmer Basket');
    }
    if (detailedPhysical['tileBrush'] == true) {
      physical.add('Tile Brush');
    }
    if (detailedPhysical['pumpBasket'] == true) {
      physical.add('Pump Basket');
    }
    if (detailedPhysical['backwash'] == true) {
      physical.add('Backwash');
    }
    if (physical.isEmpty) return const SizedBox.shrink();
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
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: physical
                .take(3)
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                  ),
                )
                .toList(),
          ),
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
            children: metrics
                .map(
                  (metric) => Text(
                    metric,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
