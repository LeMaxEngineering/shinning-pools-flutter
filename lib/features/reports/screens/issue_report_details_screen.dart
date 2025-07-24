import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../core/services/issue_reports_service.dart';
import '../../../core/services/auth_service.dart';

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;

  const IssueReportDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueReportDetailsScreen> createState() => _IssueReportDetailsScreenState();
}

class _IssueReportDetailsScreenState extends State<IssueReportDetailsScreen> {
  IssueReport? _issue;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIssueDetails();
  }

  Future<void> _loadIssueDetails() async {
    try {
      final issueReportsService = context.read<IssueReportsService>();
      final issue = await issueReportsService.getIssueReport(widget.issueId);
      
      if (mounted) {
        setState(() {
          _issue = issue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
        title: const Text('Issue Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIssueDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading issue details',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Retry',
                        onPressed: _loadIssueDetails,
                      ),
                    ],
                  ),
                )
              : _issue == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Issue not found',
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with status and priority
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _issue!.title,
                                        style: AppTextStyles.headline,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_issue!.status),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _issue!.status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(_issue!.priority),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _issue!.priority,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Issue Type', _issue!.issueType),
                                _buildInfoRow('Reported By', _issue!.reporterName),
                                _buildInfoRow('Reported At', DateFormat('MMM dd, yyyy HH:mm').format(_issue!.reportedAt)),
                                _buildInfoRow('Location', _issue!.location),
                                _buildInfoRow('Device', _issue!.deviceInfo),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _issue!.description,
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Assignment and Resolution Info
                          if (_issue!.assignedTo != null) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assignment',
                                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Assigned To', _issue!.assignedToName ?? 'Unknown'),
                                  if (_issue!.assignedAt != null)
                                    _buildInfoRow('Assigned At', DateFormat('MMM dd, yyyy HH:mm').format(_issue!.assignedAt!)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_issue!.resolution != null) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resolution',
                                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _issue!.resolution!,
                                    style: AppTextStyles.body,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow('Resolved By', _issue!.resolvedByName ?? 'Unknown'),
                                  if (_issue!.resolvedAt != null)
                                    _buildInfoRow('Resolved At', DateFormat('MMM dd, yyyy HH:mm').format(_issue!.resolvedAt!)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Action Buttons
                          if (_issue!.status != 'Resolved') ...[
                            Row(
                              children: [
                                if (_issue!.status == 'Open') ...[
                                  Expanded(
                                    child: AppButton(
                                      label: 'Start Progress',
                                      onPressed: () => _updateStatus('In Progress'),
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                if (_issue!.status == 'In Progress') ...[
                                  Expanded(
                                    child: AppButton(
                                      label: 'Resolve Issue',
                                      onPressed: () => _showResolveDialog(),
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: AppButton(
                                    label: 'Assign Issue',
                                    onPressed: () => _showAssignDialog(),
                                    color: Colors.blue,
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      final issueReportsService = context.read<IssueReportsService>();
      final success = await issueReportsService.updateIssueStatus(
        _issue!.id,
        newStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIssueDetails(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResolveDialog() {
    final TextEditingController resolutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Resolve Issue'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resolution Details', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              TextField(
                controller: resolutionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe how the issue was resolved...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (resolutionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter resolution details'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _resolveIssue(resolutionController.text.trim());
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Resolve'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resolveIssue(String resolution) async {
    try {
      final issueReportsService = context.read<IssueReportsService>();
      final success = await issueReportsService.updateIssueStatus(
        _issue!.id,
        'Resolved',
        resolution: resolution,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIssueDetails(); // Refresh the data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resolving issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAssignDialog() {
    // TODO: Implement issue assignment dialog with worker selection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue assignment coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 