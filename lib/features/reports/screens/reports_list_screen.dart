import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'report_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRecords();
  }

  Future<void> _loadMaintenanceRecords() async {
    try {
      final maintenanceSnapshot = await FirebaseFirestore.instance
          .collection('pool_maintenances')
          .get();
      final records = await Future.wait(
        maintenanceSnapshot.docs.map((doc) async {
          final data = doc.data();
          data['id'] = doc.id;

          // Fetch pool data
          if (data['poolId'] != null) {
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
                final customerSnapshot = await FirebaseFirestore.instance
                    .collection('customers')
                    .where('email', isEqualTo: poolDoc.data()!['customerEmail'])
                    .limit(1)
                    .get();
                if (customerSnapshot.docs.isNotEmpty) {
                  data['customerName'] =
                      customerSnapshot.docs.first.data()['name'] ??
                      'Unknown Owner';
                } else {
                  data['customerName'] = 'Unknown Owner';
                }
              } else {
                data['customerName'] = 'Unknown Owner';
              }
            } else {
              data['poolAddress'] = 'Unknown Address';
              data['customerName'] = 'Unknown Owner';
            }
          }
          return data;
        }),
      );

      setState(() {
        _maintenanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
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
      builder: (BuildContext context) {
        String selectedType = 'Daily';
        String selectedWorker = 'John Smith';
        
        return AlertDialog(
          title: const Text('Generate New Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.primary,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.primary,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                value: selectedType,
                items: ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.primary,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  labelText: 'Worker',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.primary,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                value: selectedWorker,
                items: ['John Smith', 'Jane Doe', 'Mike Johnson', 'All Workers']
                    .map(
                      (worker) =>
                          DropdownMenuItem(value: worker, child: Text(worker)),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedWorker = value!;
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generating $selectedType report for $selectedWorker...',
                    ),
                  ),
                );
              },
              child: const Text('Generate'),
            ),
          ],
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
                          DropdownButton<String>(
                            dropdownColor: AppColors.primary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            value: _statusFilter,
                            isExpanded: true,
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
                                        child: Text(status),
                                      ),
                                    )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _statusFilter = value!;
                              });
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
                          Text('Date: ', style: AppTextStyles.caption),
                          DropdownButton<String>(
                            dropdownColor: AppColors.primary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            value: _dateFilter,
                            isExpanded: true,
                            items:
                                ['All', 'Today', 'Last 7 Days', 'Last 30 Days']
                                    .map(
                                      (dateRange) => DropdownMenuItem(
                                        value: dateRange,
                                        child: Text(dateRange),
                                      ),
                                    )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _dateFilter = value!;
                              });
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
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                      final reportDate = (report['date'] as Timestamp).toDate();

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
                                report['poolAddress'] ?? 'Unknown Address',
                                style: AppTextStyles.subtitle,
                              ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                    report['customerName'] ?? 'Unknown Owner',
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
