import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../core/services/issue_reports_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/worker_repository.dart';
import '../../users/models/worker.dart';

class IssueReportDetailsScreen extends StatefulWidget {
  final String issueId;

  const IssueReportDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueReportDetailsScreen> createState() =>
      _IssueReportDetailsScreenState();
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
                  AppButton(label: 'Retry', onPressed: _loadIssueDetails),
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
                  Text('Issue not found', style: AppTextStyles.subtitle),
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
                        _buildInfoRow(
                          'Reported At',
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(_issue!.reportedAt),
                        ),
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
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_issue!.description, style: AppTextStyles.body),
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
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Assigned To',
                            _issue!.assignedToName ?? 'Unknown',
                          ),
                          if (_issue!.assignedAt != null)
                            _buildInfoRow(
                              'Assigned At',
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(_issue!.assignedAt!),
                            ),
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
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_issue!.resolution!, style: AppTextStyles.body),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Resolved By',
                            _issue!.resolvedByName ?? 'Unknown',
                          ),
                          if (_issue!.resolvedAt != null)
                            _buildInfoRow(
                              'Resolved At',
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(_issue!.resolvedAt!),
                            ),
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
                            label: _issue!.assignedTo != null
                                ? 'Reassign Issue'
                                : 'Assign Issue',
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
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators can assign issues'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_issue?.status == 'Resolved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot assign a resolved issue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AssignmentDialog(
          issue: _issue!,
          companyId: currentUser!.companyId!,
        );
      },
    ).then((assigned) {
      if (assigned == true) {
        _loadIssueDetails(); // Refresh the data
      }
    });
  }
}

class _AssignmentDialog extends StatefulWidget {
  final IssueReport issue;
  final String companyId;

  const _AssignmentDialog({required this.issue, required this.companyId});

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  Worker? _selectedWorker;
  List<Worker> _workers = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _dueDate;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      final workerRepository = context.read<WorkerRepository>();
      final workers = await workerRepository.getCompanyWorkers(
        widget.companyId,
      );

      if (mounted) {
        setState(() {
          _workers = workers
              .where(
                (worker) =>
                    worker.status == 'active' ||
                    worker.status == 'available' ||
                    worker.status == 'on_route',
              )
              .toList();
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

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _assignIssue() async {
    if (_selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a worker'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final issueReportsService = context.read<IssueReportsService>();
      final currentUser = context.read<AuthService>().currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Prepare assignment data
      final assignmentData = {
        'assignedTo': _selectedWorker!.id,
        'assignedToName': _selectedWorker!.name,
        'assignedBy': currentUser.id,
        'assignedByName': currentUser.name,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'Assigned',
        'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        'assignmentNotes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      };

      final success = await issueReportsService.updateIssueStatus(
        widget.issue.id,
        'Assigned',
        assignedTo: _selectedWorker!.id,
        assignedToName: _selectedWorker!.name,
      );

      if (success && mounted) {
        // Update additional assignment fields
        await FirebaseFirestore.instance
            .collection('issue_reports')
            .doc(widget.issue.id)
            .update(assignmentData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue assigned to ${_selectedWorker!.name}'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        throw Exception('Failed to assign issue');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_ind, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Assign Issue'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Issue: ${widget.issue.title}', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(
                'Error loading workers: $_error',
                style: TextStyle(color: Colors.red),
              )
            else if (_workers.isEmpty)
              Text(
                'No available workers found',
                style: TextStyle(color: Colors.orange),
              )
            else ...[
              Text('Select Worker', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              DropdownButtonFormField<Worker>(
                value: _selectedWorker,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _workers.map((worker) {
                  return DropdownMenuItem<Worker>(
                    value: worker,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            worker.name.isNotEmpty
                                ? worker.name[0].toUpperCase()
                                : 'W',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(worker.name, style: AppTextStyles.body),
                              Text(
                                worker.status
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: _getWorkerStatusColor(worker.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Worker? worker) {
                  setState(() {
                    _selectedWorker = worker;
                  });
                },
              ),
              const SizedBox(height: 16),

              Text('Due Date (Optional)', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate != null
                            ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                            : 'Select due date',
                        style: TextStyle(
                          color: _dueDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Assignment Notes (Optional)',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any specific instructions or notes...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        if (!_isLoading && _workers.isNotEmpty)
          ElevatedButton(
            onPressed: _selectedWorker != null ? _assignIssue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Assign Issue'),
          ),
      ],
    );
  }

  Color _getWorkerStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'available':
        return Colors.blue;
      case 'on_route':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
