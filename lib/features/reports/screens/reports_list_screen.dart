import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'report_details_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final List<Map<String, dynamic>> _reports = [
    {
      'id': '1',
      'title': 'Daily Work Report',
      'type': 'Daily',
      'date': '2024-01-15',
      'worker': 'John Smith',
      'status': 'Completed',
      'poolsCompleted': 8,
      'totalPools': 10,
      'hoursWorked': 7.5,
      'issues': 2,
      'notes': 'Completed most pools on time. Two pools had minor issues.',
      'route': 'Morning Route - Downtown',
    },
    {
      'id': '2',
      'title': 'Weekly Performance Report',
      'type': 'Weekly',
      'date': '2024-01-08 to 2024-01-14',
      'worker': 'John Smith',
      'status': 'Completed',
      'poolsCompleted': 45,
      'totalPools': 50,
      'hoursWorked': 38.5,
      'issues': 5,
      'notes': 'Good week overall. Met 90% of targets.',
      'route': 'All Routes',
    },
    {
      'id': '3',
      'title': 'Monthly Maintenance Report',
      'type': 'Monthly',
      'date': 'December 2023',
      'worker': 'All Workers',
      'status': 'Completed',
      'poolsCompleted': 180,
      'totalPools': 200,
      'hoursWorked': 160,
      'issues': 15,
      'notes': 'Monthly maintenance completed. Some equipment needs replacement.',
      'route': 'All Routes',
    },
    {
      'id': '4',
      'title': 'Customer Satisfaction Report',
      'type': 'Quarterly',
      'date': 'Q4 2023',
      'worker': 'N/A',
      'status': 'In Progress',
      'poolsCompleted': 0,
      'totalPools': 0,
      'hoursWorked': 0,
      'issues': 0,
      'notes': 'Survey in progress. Results expected next week.',
      'route': 'N/A',
    },
    {
      'id': '5',
      'title': 'Equipment Maintenance Report',
      'type': 'Monthly',
      'date': 'January 2024',
      'worker': 'Maintenance Team',
      'status': 'Draft',
      'poolsCompleted': 0,
      'totalPools': 0,
      'hoursWorked': 0,
      'issues': 8,
      'notes': 'Equipment inspection in progress.',
      'route': 'N/A',
    },
  ];

  String _typeFilter = 'All';
  String _statusFilter = 'All';
  String _dateFilter = 'All';

  List<Map<String, dynamic>> get _filteredReports {
    return _reports.where((report) {
      final matchesType = _typeFilter == 'All' || report['type'] == _typeFilter;
      final matchesStatus = _statusFilter == 'All' || report['status'] == _statusFilter;
      final matchesDate = _dateFilter == 'All' || report['date'].contains(_dateFilter);
      
      return matchesType && matchesStatus && matchesDate;
    }).toList();
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
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(report: report),
      ),
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
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedWorker,
                decoration: const InputDecoration(
                  labelText: 'Worker',
                  border: OutlineInputBorder(),
                ),
                items: ['John Smith', 'Jane Doe', 'Mike Johnson', 'All Workers']
                    .map((worker) => DropdownMenuItem(
                          value: worker,
                          child: Text(worker),
                        ))
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
                  SnackBar(content: Text('Generating $selectedType report for $selectedWorker...')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${report['title']}...')),
    );
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
                          Text('Type: ', style: AppTextStyles.caption),
                          DropdownButton<String>(
                            value: _typeFilter,
                            isExpanded: true,
                            items: ['All', 'Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly']
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ', style: AppTextStyles.caption),
                          DropdownButton<String>(
                            value: _statusFilter,
                            isExpanded: true,
                            items: ['All', 'Completed', 'In Progress', 'Draft', 'Pending']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
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
                          style: AppTextStyles.headline.copyWith(color: AppColors.primary),
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
                          style: AppTextStyles.headline.copyWith(color: Colors.green),
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
                          style: AppTextStyles.headline.copyWith(color: Colors.orange),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(report['type']),
                          child: Icon(
                            _getReportIcon(report['type']),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(report['title'], style: AppTextStyles.subtitle),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${report['date']}'),
                            Text('Worker: ${report['worker']}'),
                            if (report['route'] != 'N/A')
                              Text('Route: ${report['route']}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report['status'],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      
                      // Report Metrics
                      if (report['poolsCompleted'] > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${report['poolsCompleted']}/${report['totalPools']}',
                                          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                                        ),
                                        Text('Pools', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${report['hoursWorked']}h',
                                          style: AppTextStyles.subtitle.copyWith(color: Colors.blue),
                                        ),
                                        Text('Hours', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${report['issues']}',
                                          style: AppTextStyles.subtitle.copyWith(color: Colors.orange),
                                        ),
                                        Text('Issues', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: report['totalPools'] > 0 
                                    ? report['poolsCompleted'] / report['totalPools'] 
                                    : 0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getStatusColor(report['status']),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Notes Preview
                      if (report['notes'] != null && report['notes'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes:', style: AppTextStyles.caption),
                              Text(
                                report['notes'],
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'View Details',
                                onPressed: () => _viewReport(report),
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                label: 'Export',
                                onPressed: () => _exportReport(report),
                                color: Colors.green,
                              ),
                            ),
                          ],
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

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'Daily':
        return Icons.today;
      case 'Weekly':
        return Icons.view_week;
      case 'Monthly':
        return Icons.calendar_month;
      case 'Quarterly':
        return Icons.assessment;
      case 'Yearly':
        return Icons.calendar_today;
      default:
        return Icons.description;
    }
  }
} 