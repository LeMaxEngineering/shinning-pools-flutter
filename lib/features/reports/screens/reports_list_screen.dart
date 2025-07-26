import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'report_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import 'package:provider/provider.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  List<Map<String, dynamic>> _maintenanceRecords = [];
  bool _isLoading = true;

  String _statusFilter = 'All';
  String _dateFilter = 'All';

  // Pagination variables
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMoreData = true;

  List<Map<String, dynamic>> get _filteredReports {
    return _maintenanceRecords.where((report) {
      final matchesStatus =
          _statusFilter == 'All' || report['status'] == _statusFilter;

      bool matchesDate = _dateFilter == 'All';
      if (_dateFilter != 'All' && report['date'] is Timestamp) {
        final reportDate = (report['date'] as Timestamp).toDate();
        if (_dateFilter == 'Today') {
          matchesDate = DateUtils.isSameDay(reportDate, DateTime.now());
        } else if (_dateFilter == 'Last 7 Days') {
          matchesDate = reportDate.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          );
        } else if (_dateFilter == 'Last 30 Days') {
          matchesDate = reportDate.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          );
        }
      }

      return matchesStatus && matchesDate;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedReports {
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    final filtered = _filteredReports;

    // Update hasMoreData flag
    _hasMoreData = endIndex < filtered.length;

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  void _nextPage() {
    if (_hasMoreData) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRecords();
  }

  Future<void> _loadMaintenanceRecords() async {
    try {
      // Get current user and company ID
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser?.companyId == null) {
        throw Exception('No company information found');
      }

      print(
        '🔍 Loading maintenance records for company: ${currentUser!.companyId}',
      );
      print('🔍 Current user ID: ${currentUser.id}');
      print('🔍 Current user role: ${currentUser.role}');
      print('🔍 Current user email: ${currentUser.email}');

      // For now, get all maintenance records without company filter to test
      print(
        '🔍 Executing Firestore query: collection("pool_maintenances").get()',
      );
      final maintenanceSnapshot = await FirebaseFirestore.instance
          .collection('pool_maintenances')
          .get();
      final records = await Future.wait(
        maintenanceSnapshot.docs.map((doc) async {
          final data = doc.data();
          data['id'] = doc.id;

          // Fetch pool data
          if (data['poolId'] != null) {
            print('🔍 Fetching pool data for poolId: ${data['poolId']}');
            try {
              final poolDoc = await FirebaseFirestore.instance
                  .collection('pools')
                  .doc(data['poolId'])
                  .get();
              if (poolDoc.exists) {
                data['poolAddress'] =
                    poolDoc.data()?['address'] ?? 'Unknown Address';
                data['poolData'] = poolDoc.data(); // Store full pool data
                // Fetch customer data using customerId from pool
                if (poolDoc.data()?['customerEmail'] != null) {
                  try {
                    final customerSnapshot = await FirebaseFirestore.instance
                        .collection('customers')
                        .where(
                          'email',
                          isEqualTo: poolDoc.data()!['customerEmail'],
                        )
                        .limit(1)
                        .get();
                    if (customerSnapshot.docs.isNotEmpty) {
                      data['customerName'] =
                          customerSnapshot.docs.first.data()['name'] ??
                          'Unknown Owner';
                    } else {
                      data['customerName'] = 'Unknown Owner';
                    }
                  } catch (customerError) {
                    print('❌ Error fetching customer data: $customerError');
                    data['customerName'] = 'Unknown Owner';
                  }
                } else {
                  data['customerName'] = 'Unknown Owner';
                }
              } else {
                data['poolAddress'] = 'Unknown Address';
                data['customerName'] = 'Unknown Owner';
              }
            } catch (poolError) {
              print(
                '❌ Error fetching pool data for ${data['poolId']}: $poolError',
              );
              data['poolAddress'] = 'Address Unavailable';
              data['customerName'] = 'Owner Unavailable';
              data['poolData'] = null;
            }
          }
          return data;
        }),
      );

      print('🔍 Found ${records.length} maintenance records');

      // Log the structure of the first few records to understand the data
      if (records.isNotEmpty) {
        print('🔍 Sample record structure:');
        final sampleRecord = records.first;
        sampleRecord.forEach((key, value) {
          print('  - $key: $value');
        });
      }

      // Filter records to only show those belonging to the current company
      final companyRecords = records.where((record) {
        // Check if the record has companyId field and it matches
        if (record['companyId'] != null) {
          return record['companyId'] == currentUser.companyId;
        }
        // If no companyId field, check if the pool belongs to the company
        if (record['poolData'] != null &&
            record['poolData']['companyId'] != null) {
          return record['poolData']['companyId'] == currentUser.companyId;
        }
        // If we can't determine company due to permission error, include it
        // since the user has access to the maintenance record
        return true;
      }).toList();

      print(
        '🔍 Filtered to ${companyRecords.length} records for company ${currentUser.companyId}',
      );

      setState(() {
        _maintenanceRecords = companyRecords;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading maintenance records: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Draft':
        return Colors.grey;
      case 'Pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Daily':
        return Colors.blue;
      case 'Weekly':
        return Colors.green;
      case 'Monthly':
        return Colors.orange;
      case 'Quarterly':
        return Colors.purple;
      case 'Yearly':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _viewReport(Map<String, dynamic> report) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: report)),
    );
  }

  void _generateNewReport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String selectedType = 'Daily';
        String selectedWorker = 'John Smith';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assessment,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate New Report',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a new maintenance report',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Report Type Section
                Text(
                  'Report Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      items:
                          ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        selectedType = value!;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Worker Section
                Text(
                  'Assigned Worker',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedWorker,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      items:
                          [
                                'John Smith',
                                'Jane Doe',
                                'Mike Johnson',
                                'All Workers',
                              ]
                              .map(
                                (worker) => DropdownMenuItem(
                                  value: worker,
                                  child: Text(worker),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        selectedWorker = value!;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Generating $selectedType report for $selectedWorker...',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Generate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  void _exportReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporting ${report['title']}...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateNewReport,
            tooltip: 'Generate New Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Filter Row 1
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ', style: AppTextStyles.caption),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                              value: _statusFilter,
                              isExpanded: true,
                              underline:
                                  Container(), // Remove default underline
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              items:
                                  [
                                        'All',
                                        'Completed',
                                        'In Progress',
                                        'Scheduled',
                                        'Cancelled',
                                      ]
                                      .map(
                                        (status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(
                                            status,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _statusFilter = value!;
                                  _resetPagination();
                                });
                              },
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
                          Text('Date: ', style: AppTextStyles.caption),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                              value: _dateFilter,
                              isExpanded: true,
                              underline:
                                  Container(), // Remove default underline
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              items:
                                  [
                                        'All',
                                        'Today',
                                        'Last 7 Days',
                                        'Last 30 Days',
                                      ]
                                      .map(
                                        (dateRange) => DropdownMenuItem(
                                          value: dateRange,
                                          child: Text(
                                            dateRange,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _dateFilter = value!;
                                  _resetPagination();
                                });
                              },
                            ),
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
                          '${_filteredReports.length}',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text('Total Reports', style: AppTextStyles.caption),
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
                          '${_filteredReports.where((r) => r['status'] == 'Completed').length}',
                          style: AppTextStyles.headline.copyWith(
                            color: Colors.green,
                          ),
                        ),
                        Text('Completed', style: AppTextStyles.caption),
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
                          '${_filteredReports.where((r) => r['status'] == 'In Progress').length}',
                          style: AppTextStyles.headline.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                        Text('In Progress', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reports List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                ? Center(
                    child: Text('No reports found.', style: AppTextStyles.body),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _paginatedReports.length,
                          itemBuilder: (context, index) {
                            final report = _paginatedReports[index];
                            final reportDate = (report['date'] as Timestamp)
                                .toDate();

                            return AppCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getStatusColor(
                                        report['status'] ?? 'Completed',
                                      ),
                                      child: Icon(
                                        _getReportIcon(
                                          report['status'] ?? 'Completed',
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      report['poolAddress'] ??
                                          'Unknown Address',
                                      style: AppTextStyles.subtitle,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report['customerName'] ??
                                              'Unknown Owner',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Date: ${DateFormat('MMMM dd, yyyy').format(reportDate)}',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Worker: ${report['performedByName'] ?? 'N/A'}',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          report['status'] ?? 'Completed',
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        report['status'] ?? 'Completed',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Action Buttons
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: AppButton(
                                      label: 'View Details',
                                      onPressed: () => _viewReport(report),
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Pagination Controls
                      if (_filteredReports.length > _pageSize)
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Page ${_currentPage + 1} of ${(_filteredReports.length / _pageSize).ceil()}',
                                style: AppTextStyles.caption,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _currentPage > 0
                                        ? _previousPage
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                    color: _currentPage > 0
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                  Text(
                                    '${_currentPage + 1}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _hasMoreData ? _nextPage : null,
                                    icon: const Icon(Icons.chevron_right),
                                    color: _hasMoreData
                                        ? AppColors.primary
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateNewReport,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getReportIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.hourglass_top;
      case 'Scheduled':
        return Icons.calendar_today;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }
}
