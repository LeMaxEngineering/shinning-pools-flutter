import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../core/services/issue_reports_service.dart';
import '../../../core/services/auth_service.dart';
import 'issue_report_details_screen.dart';

class IssueReportsListScreen extends StatefulWidget {
  const IssueReportsListScreen({super.key});

  @override
  State<IssueReportsListScreen> createState() => _IssueReportsListScreenState();
}

class _IssueReportsListScreenState extends State<IssueReportsListScreen> {
  String _statusFilter = 'All';
  String _priorityFilter = 'All';
  String _typeFilter = 'All';
  bool _showOnlyCritical = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssueReports();
    });
  }

  Future<void> _loadIssueReports() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser?.companyId != null) {
      final issueReportsService = context.read<IssueReportsService>();
      await issueReportsService.loadIssueReports(currentUser!.companyId!);
    }
  }

  List<IssueReport> get _filteredReports {
    final issueReportsService = context.read<IssueReportsService>();
    var filtered = issueReportsService.issueReports;

    if (_statusFilter != 'All') {
      filtered = filtered
          .where((issue) => issue.status == _statusFilter)
          .toList();
    }

    if (_priorityFilter != 'All') {
      filtered = filtered
          .where((issue) => issue.priority == _priorityFilter)
          .toList();
    }

    if (_typeFilter != 'All') {
      filtered = filtered
          .where((issue) => issue.issueType == _typeFilter)
          .toList();
    }

    if (_showOnlyCritical) {
      filtered = filtered
          .where((issue) => issue.priority == 'Critical')
          .toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.red;
      case 'In Progress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIssueReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<IssueReportsService>(
        builder: (context, issueReportsService, child) {
          if (issueReportsService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (issueReportsService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading issue reports',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issueReportsService.error!,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(label: 'Retry', onPressed: _loadIssueReports),
                ],
              ),
            );
          }

          final stats = issueReportsService.getIssueStatistics();

          return Column(
            children: [
              // Statistics Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        stats['active'].toString(),
                        Icons.report_problem,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Open',
                        stats['open'].toString(),
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Critical',
                        stats['critical'].toString(),
                        Icons.priority_high,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'Status',
                            _statusFilter,
                            ['All', 'Open', 'In Progress', 'Resolved'],
                            (value) => setState(() => _statusFilter = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown(
                            'Priority',
                            _priorityFilter,
                            ['All', 'Low', 'Medium', 'High', 'Critical'],
                            (value) => setState(() => _priorityFilter = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'Type',
                            _typeFilter,
                            [
                              'All',
                              'Equipment',
                              'Chemical',
                              'Water Quality',
                              'Safety',
                              'Access',
                              'Other',
                            ],
                            (value) => setState(() => _typeFilter = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Critical Only',
                              style: AppTextStyles.caption,
                            ),
                            value: _showOnlyCritical,
                            onChanged: (value) =>
                                setState(() => _showOnlyCritical = value!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Issue Reports List
              Expanded(
                child: _filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No issue reports found',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No issues match the current filters',
                              style: AppTextStyles.body,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final issue = _filteredReports[index];
                          return _buildIssueCard(issue);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline.copyWith(color: color)),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildIssueCard(IssueReport issue) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reported by ${issue.reporterName}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issue.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(issue.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      issue.priority,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(issue.issueType, style: AppTextStyles.caption),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(issue.reportedAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            issue.description,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'View Details',
                  onPressed: () => _viewIssueDetails(issue),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              if (issue.status == 'Open')
                Expanded(
                  child: AppButton(
                    label: 'Assign',
                    onPressed: () => _assignIssue(issue),
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewIssueDetails(IssueReport issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueReportDetailsScreen(issueId: issue.id),
      ),
    );
  }

  void _assignIssue(IssueReport issue) {
    // TODO: Implement issue assignment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue assignment coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
