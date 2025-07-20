import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../viewmodels/worker_viewmodel.dart';
import '../models/worker.dart';
import 'associated_form_screen.dart';
import 'worker_edit_screen.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class AssociatedListScreen extends StatefulWidget {
  const AssociatedListScreen({super.key});

  @override
  State<AssociatedListScreen> createState() => _AssociatedListScreenState();
}

class _AssociatedListScreenState extends State<AssociatedListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerViewModel>(context, listen: false).initialize();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'On Route':
        return Colors.blue;
      case 'Available':
        return Colors.orange;
      case 'Inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addNewWorker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssociatedFormScreen()),
    );
  }

  void _editWorker(Worker worker) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkerEditScreen(worker: worker)),
    );
  }

  void _viewWorkerDetails(Worker worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                children: [
                  Text('Worker Details', style: AppTextStyles.headline2),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Worker Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    backgroundImage: worker.photoUrl != null ? NetworkImage(worker.photoUrl!) : null,
                    child: worker.photoUrl == null
                        ? Text(
                            _getInitials(worker.name),
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.name, style: AppTextStyles.headline),
                        const SizedBox(height: 4),
                        Text(worker.email, style: AppTextStyles.body),
                        if (worker.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(worker.phone, style: AppTextStyles.body),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Status and Stats
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(worker.statusDisplay),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      worker.statusDisplay,
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('${worker.poolsAssigned} pools', style: AppTextStyles.body),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      Text(worker.rating.toStringAsFixed(1), style: AppTextStyles.body),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Last active: ${worker.lastActiveDisplay}', style: AppTextStyles.caption.copyWith(color: Colors.grey)),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Worker',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editWorker(worker);
                      },
                      icon: Icons.edit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'View Pools',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _viewWorkerPools(worker);
                      },
                      icon: Icons.pool,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Send Message',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _sendMessageToWorker(worker);
                      },
                      icon: Icons.message,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Delete Worker',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteWorker(worker);
                      },
                      icon: Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _deleteWorker(Worker worker) {
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Worker'),
          content: Text('Are you sure you want to delete ${worker.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await viewModel.deleteWorker(worker.id);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${worker.name} has been deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete worker: ${viewModel.error}'),
                        backgroundColor: Colors.red,
                      ),
                );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _viewWorkerPools(Worker worker) {
    // TODO: Navigate to pools list filtered by this worker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing pools assigned to ${worker.name}'),
        backgroundColor: Colors.blue,
      ),
    );
    // Future implementation: Navigate to pools list with worker filter
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => PoolsListScreen(workerFilter: worker.id),
    //   ),
    // );
  }

  void _sendMessageToWorker(Worker worker) {
    // TODO: Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Messaging feature coming soon for ${worker.name}'),
        backgroundColor: Colors.green,
      ),
    );
    // Future implementation: Open messaging interface
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) => MessageScreen(recipient: worker),
    //   ),
    // );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    } else if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkerViewModel>(
      builder: (context, viewModel, child) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workers Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
                onPressed: _addNewWorker,
            tooltip: 'Add New Worker',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.refresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${viewModel.error}',
                            style: AppTextStyles.body.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Retry',
                            onPressed: viewModel.refresh,
          ),
        ],
      ),
                    )
                  : Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Find Workers', style: AppTextStyles.subtitle),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: '',
                    hint: 'Search workers...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    onChanged: viewModel.updateSearchQuery,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Status:', style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: viewModel.statusFilter,
                          dropdownColor: AppColors.primary,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            filled: true,
                            fillColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: ['All', 'Active', 'On Route', 'Available', 'Inactive']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status, style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              viewModel.updateStatusFilter(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section Title for Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text('Worker Overview', style: AppTextStyles.headline2),
          ),

          // Statistics Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppCard(
                    backgroundColor: Colors.white,
                    child: Column(
                      children: [
                        Text(
                          viewModel.totalWorkers.toString(),
                          style: AppTextStyles.headline.copyWith(color: AppColors.primary),
                        ),
                        Text('Total Workers', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    backgroundColor: Colors.white,
                    child: Column(
                      children: [
                        Text(
                          viewModel.activeWorkers.toString(),
                          style: AppTextStyles.headline.copyWith(color: Colors.green),
                        ),
                        Text('Active', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    backgroundColor: Colors.white,
                    child: Column(
                      children: [
                        Text(
                          viewModel.onRouteWorkers.toString(),
                          style: AppTextStyles.headline.copyWith(color: Colors.blue),
                        ),
                        Text('On Route', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Workers List
          Expanded(
            child: viewModel.filteredWorkers.isEmpty
                ? const Center(
                    child: Text(
                      'No workers found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: viewModel.filteredWorkers.length,
                    itemBuilder: (context, index) {
                      final worker = viewModel.filteredWorkers[index];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        backgroundColor: Colors.white,
                        child: ListTile(
                          onTap: () => _viewWorkerDetails(worker),
                          leading: CircleAvatar(
                            backgroundColor: worker.statusDisplay == 'Active'
                                ? AppColors.success
                                : worker.statusDisplay == 'On Route'
                                    ? AppColors.info
                                    : worker.statusDisplay == 'Available'
                                        ? AppColors.warning
                                        : AppColors.grey,
                            backgroundImage: (worker.photoUrl != null && worker.photoUrl!.isNotEmpty)
                                ? NetworkImage(worker.photoUrl!)
                                : null,
                            child: (worker.photoUrl == null || worker.photoUrl!.isEmpty)
                                ? Text(
                                    _getInitials(worker.name),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  )
                                : null,
                          ),
                          title: Text(worker.name, style: AppTextStyles.subtitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(worker.email, style: TextStyle(color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(worker.statusDisplay),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      worker.statusDisplay,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${worker.poolsAssigned} pools'),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      Text('${worker.rating.toStringAsFixed(1)}'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last active: ${worker.lastActiveDisplay}',
                                style: AppTextStyles.caption.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewWorkerDetails(worker);
                                  break;
                                case 'edit':
                                  _editWorker(worker);
                                  break;
                                case 'delete':
                                  _deleteWorker(worker);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
            onPressed: _addNewWorker,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
        );
      },
    );
  }
} 