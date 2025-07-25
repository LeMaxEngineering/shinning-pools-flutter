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

class HistoricalWorkerMaintenanceList extends StatefulWidget {
  const HistoricalWorkerMaintenanceList({Key? key}) : super(key: key);

  @override
  State<HistoricalWorkerMaintenanceList> createState() =>
      _HistoricalWorkerMaintenanceListState();
}

class _HistoricalWorkerMaintenanceListState
    extends State<HistoricalWorkerMaintenanceList> {
  String? _selectedPoolId;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _workerMaintenances = [];
  bool _maintenancesLoaded = false;
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_maintenancesLoaded) {
      _loadHistoricalMaintenances();
    }
  }

  Future<void> _loadHistoricalMaintenances({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final workerId = authService.currentUser?.id;

    if (workerId == null) {
      setState(() {
        _isLoading = false;
        _maintenancesLoaded = true;
      });
      return;
    }

    try {
      // Build query for historical maintenance records
      Query query = FirebaseFirestore.instance
          .collection('pool_maintenances')
          .where('performedById', isEqualTo: workerId)
          .orderBy('date', descending: true);

      // Apply filters
      if (_selectedStatus != null) {
        query = query.where('status', isEqualTo: _selectedStatus);
      }
      if (_startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
        );
      }
      if (_endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(_endDate!),
        );
      }

      // Apply pagination
      if (loadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(_pageSize);

      final snapshot = await query.get();

      debugPrint('🔍 Historical Maintenance Query Debug:');
      debugPrint('  - Worker ID: $workerId');
      debugPrint('  - Status filter: $_selectedStatus');
      debugPrint('  - Start date: $_startDate');
      debugPrint('  - End date: $_endDate');
      debugPrint('  - Documents found: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        debugPrint('  - No maintenance records found for this worker');
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
        return;
      }

      // Process maintenance records
      final newMaintenances = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final poolId = data['poolId'] as String?;

          String? poolAddress;
          String? customerName;

          // Fetch pool information to get customer name
          if (poolId != null) {
            try {
              final currentUser = authService.currentUser;
              final companyId = currentUser?.companyId;

              if (companyId != null) {
                final poolQuery = await FirebaseFirestore.instance
                    .collection('pools')
                    .where('companyId', isEqualTo: companyId)
                    .get();

                final poolDoc = poolQuery.docs
                    .where((doc) => doc.id == poolId)
                    .firstOrNull;

                if (poolDoc != null) {
                  final poolData = poolDoc.data() as Map<String, dynamic>;
                  poolAddress = poolData['address'] as String?;
                  final customerEmail = poolData['customerEmail'] as String?;

                  if (customerEmail != null) {
                    final customerQuery = await FirebaseFirestore.instance
                        .collection('customers')
                        .where('companyId', isEqualTo: companyId)
                        .where('email', isEqualTo: customerEmail)
                        .limit(1)
                        .get();

                    if (customerQuery.docs.isNotEmpty) {
                      final customerData =
                          customerQuery.docs.first.data()
                              as Map<String, dynamic>;
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

      if (mounted) {
        setState(() {
          if (loadMore) {
            _workerMaintenances.addAll(
              newMaintenances.cast<Map<String, dynamic>>(),
            );
          } else {
            _workerMaintenances = newMaintenances.cast<Map<String, dynamic>>();
          }
          _lastDocument = snapshot.docs.last;
          _hasMoreData = snapshot.docs.length == _pageSize;
          _maintenancesLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading historical maintenance records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _maintenancesLoaded = true;
        });
      }
    }
  }

  void _refreshData() {
    setState(() {
      _lastDocument = null;
      _hasMoreData = true;
      _maintenancesLoaded = false;
    });
    _loadHistoricalMaintenances();
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

  Widget _buildFilters(
    BuildContext context,
    PoolService poolService,
    String workerId,
  ) {
    final uniquePools = _getUniquePoolsFromMaintenances();
    final statusOptions = [
      'Completed',
      'In Progress',
      'Scheduled',
      'Cancelled',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pool Filter
        if (uniquePools.isNotEmpty) ...[
          Text('Filter by Pool:', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPoolId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('All Pools'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Pools'),
              ),
              ...uniquePools.map(
                (pool) => DropdownMenuItem<String>(
                  value: pool['poolId'],
                  child: Text(pool['poolAddress'] ?? 'Unknown Pool'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPoolId = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Status Filter
        Text('Filter by Status:', style: AppTextStyles.caption),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('All Statuses'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Statuses'),
            ),
            ...statusOptions.map(
              (status) =>
                  DropdownMenuItem<String>(value: status, child: Text(status)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Date Range Filters
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From Date:', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _startDate ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat('MMM dd, yyyy').format(_startDate!)
                            : 'Select Date',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To Date:', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('MMM dd, yyyy').format(_endDate!)
                            : 'Select Date',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.filter_list),
                label: const Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPoolId = null;
                    _selectedStatus = null;
                    _startDate = null;
                    _endDate = null;
                  });
                  _refreshData();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final poolService = context.read<PoolService>();
    final currentUser = context.read<AuthService>().currentUser;

    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }

    final filteredMaintenances = _getFilteredMaintenances();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Text(
              'Historical Maintenance Records',
              style: AppTextStyles.headline,
            ),
          ),
          _buildFilters(context, poolService, currentUser.id),
          const SizedBox(height: 16),

          if (_isLoading && _workerMaintenances.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (filteredMaintenances.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No maintenance records found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You haven\'t performed any maintenance yet.\nStart by reporting your first maintenance!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ...filteredMaintenances.map((maintenance) {
                  final date = (maintenance['date'] as Timestamp?)?.toDate();
                  final formattedDate = date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Unknown Date';

                  return AppCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(maintenance['status']),
                        child: Icon(
                          _getStatusIcon(maintenance['status']),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        maintenance['poolAddress'] ?? 'Unknown Address',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maintenance['customerName'] ?? 'Unknown Owner',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          if (maintenance['status'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  maintenance['status'],
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                maintenance['status'],
                                style: AppTextStyles.caption.copyWith(
                                  color: _getStatusColor(maintenance['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MaintenanceDetailsScreen(
                                maintenanceId: maintenance['id'],
                                maintenanceData: maintenance,
                              ),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MaintenanceDetailsScreen(
                              maintenanceId: maintenance['id'],
                              maintenanceData: maintenance,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),

                // Load more button
                if (_hasMoreData)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _hasMoreData && !_isLoading
                            ? () => _loadHistoricalMaintenances(loadMore: true)
                            : null,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load More'),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.work;
      case 'scheduled':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
