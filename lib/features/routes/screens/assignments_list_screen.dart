import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/features/routes/models/assignment.dart';
import 'package:shinning_pools_flutter/features/routes/models/route.dart';
import 'package:shinning_pools_flutter/features/routes/viewmodels/route_viewmodel.dart';
import 'package:shinning_pools_flutter/features/users/models/worker.dart';
import 'package:shinning_pools_flutter/features/users/viewmodels/worker_viewmodel.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_card.dart';
import '../services/assignment_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/features/routes/viewmodels/assignment_viewmodel.dart';

class AssignmentsListScreen extends StatefulWidget {
  const AssignmentsListScreen({super.key});

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  String? _selectedWorkerId;
  String? _selectedRouteId;
  DateTime? _selectedDate;
  final _notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final AssignmentService _assignmentService = AssignmentService();

  // Separate form fields for editing assignments
  String? _editWorkerId;
  String? _editRouteId;
  DateTime? _editDate;
  final _editNotesController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  // Cache for route and worker names
  final Map<String, String> _routeNameCache = {};
  final Map<String, String> _workerNameCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerViewModel>(context, listen: false).loadWorkers();
      Provider.of<RouteViewModel>(context, listen: false).loadRoutes();
      Provider.of<AssignmentViewModel>(context, listen: false).initialize();
    });
  }

  // Fetch route name if not cached
  Future<String> _getRouteName(String routeId) async {
    if (_routeNameCache.containsKey(routeId)) {
      return _routeNameCache[routeId]!;
    }

    try {
      final routeViewModel = Provider.of<RouteViewModel>(context, listen: false);
      final routes = routeViewModel.routes;
      final route = routes.firstWhere(
        (r) => r.id == routeId,
        orElse: () => RouteModel(
          id: '',
          companyId: '',
          routeName: 'Unknown Route',
          stops: [],
          status: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final routeName = route.routeName.isNotEmpty ? route.routeName : 'Unknown Route';
      _routeNameCache[routeId] = routeName;
      return routeName;
    } catch (e) {
      _routeNameCache[routeId] = 'Unknown Route';
      return 'Unknown Route';
    }
  }

  // Fetch worker name if not cached
  Future<String> _getWorkerName(String workerId) async {
    if (_workerNameCache.containsKey(workerId)) {
      return _workerNameCache[workerId]!;
    }

    try {
      final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
      final workers = workerViewModel.workers;
      final worker = workers.firstWhere(
        (w) => w.id == workerId,
        orElse: () => Worker(
          id: '',
          name: 'Unknown Worker',
          email: '',
          phone: '',
          companyId: '',
          status: '',
          poolsAssigned: 0,
          rating: 0.0,
          lastActive: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final workerName = worker.name.isNotEmpty ? worker.name : 'Unknown Worker';
      _workerNameCache[workerId] = workerName;
      return workerName;
    } catch (e) {
      _workerNameCache[workerId] = 'Unknown Worker';
      return 'Unknown Worker';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignRouteForm(),
            const SizedBox(height: 20),
            _buildManualExpirationButton(),
            const SizedBox(height: 20),
            const Text('Current Assignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildAssignmentsList(),
          ],
              ),
            ),
    );
  }

  Widget _buildAssignRouteForm() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text('Assign Route',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
                  Consumer<WorkerViewModel>(
                    builder: (context, workerViewModel, child) {
                      if (workerViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (workerViewModel.error.isNotEmpty) {
                    return Text(
                        'Error loading workers: ${workerViewModel.error}');
                      }
                      if (workerViewModel.workers.isEmpty) {
                        return const Text('No workers found.');
                      }
                      return DropdownButtonFormField<String>(
                        decoration:
                        const InputDecoration(labelText: 'Select Assignee'),
                        value: _selectedWorkerId,
                        items: workerViewModel.workers
                            .map((worker) => DropdownMenuItem(
                                  value: worker.id,
                                  child: Text(worker.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWorkerId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a worker' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Consumer<RouteViewModel>(
                    builder: (context, routeViewModel, child) {
                      if (routeViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (routeViewModel.error != null) {
                    return Text(
                        'Error loading routes: ${routeViewModel.error}');
                      }
                      if (routeViewModel.routes.isEmpty) {
                        return const Text('No routes found.');
                      }
                      return DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Select Route'),
                        value: _selectedRouteId,
                        items: routeViewModel.routes
                            .map((route) => DropdownMenuItem(
                              value: route.id,
                              child: Text(route.routeName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRouteId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a route' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(_selectedDate == null
                        ? 'Select Route Date'
                        : 'Route Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  ),
                maxLines: 3,
              ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _assignRoute,
                    child: const Text('Assign Route'),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildManualExpirationButton() {
    return Consumer<AssignmentViewModel>(
      builder: (context, assignmentViewModel, child) {
        // Only show for admin and root users
        final currentUser = assignmentViewModel.currentUser;
        if (currentUser?.role != 'admin' && currentUser?.role != 'root') {
          return const SizedBox.shrink();
        }

        // TODO: Re-enable after CORS issue is resolved
        return const SizedBox.shrink();

        /*
        return AppCard(
          backgroundColor: Colors.orange.shade600,
          child: Padding(
            padding: const EdgeInsets.all(16
            child: Row(
              children:         Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule, size:32olor: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                       Manual Route Expiration',
                        style: AppTextStyles.subtitle.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                       Checkand expire overdue routes and assignments',
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: assignmentViewModel.isLoading
                      ? null
                      : () async {
                          await assignmentViewModel.checkAndExpireRoutes();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Route expiration check completed'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  icon: assignmentViewModel.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    assignmentViewModel.isLoading ?Checking...' : Check & Expire                   style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
        */
      },
    );
  }

  Widget _buildAssignmentsList() {
    return Consumer<AssignmentViewModel>(
      builder: (context, assignmentViewModel, child) {
        if (assignmentViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = assignmentViewModel.assignments;
        if (assignments.isEmpty) {
          return const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No assignments found.'),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Only show current assignments (not historical)
        final currentAssignments = assignments
            .where((a) =>
                a.routeDate != null &&
                (a.routeDate!.isAtSameMomentAs(today) ||
                    a.routeDate!.isAfter(today)) &&
                !a.isHistorical) // Exclude historical assignments (including Closed status)
            .toList();
        currentAssignments
            .sort((a, b) => a.routeDate!.compareTo(b.routeDate!));

        // Color scheme for assignment cards (matching Route List style)
        final cardColors = [
          AppColors.primary,
          AppColors.success,
          Colors.orange,
          Colors.deepPurple,
          Colors.teal,
          Colors.indigo,
        ];

        return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            if (currentAssignments.isEmpty)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No current assignments found.'),
                  ),
                ),
              ),
            if (currentAssignments.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentAssignments.length,
                itemBuilder: (context, index) {
                  final assignment = currentAssignments[index];
                  return AppCard(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    backgroundColor: cardColors[index % cardColors.length],
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: _getRouteName(assignment.routeId),
                                builder: (context, snapshot) {
                                  final routeName = snapshot.data ?? 'Loading...';
                                  return Text(
                                    'Route Assignment: $routeName',
                                    style: AppTextStyles.subtitle.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<String>(
                                future: _getWorkerName(assignment.workerId),
                                builder: (context, snapshot) {
                                  final workerName = snapshot.data ?? 'Loading...';
                                  return Text(
                                    'Worker: $workerName',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${assignment.routeDate != null ? DateFormat('MMMM dd, yyyy').format(assignment.routeDate!) : 'No date'}',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Notes: ${assignment.notes}',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            assignment.status.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Action buttons for current assignments
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // View button
                            IconButton(
                              onPressed: () => _viewAssignment(assignment),
                              icon: const Icon(Icons.visibility, color: Colors.white),
                              tooltip: 'View Details',
                            ),
                            // Edit button
                            IconButton(
                              onPressed: () => _editAssignment(assignment),
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Edit Assignment',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _pickEditDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _editDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (date != null) {
      setState(() {
        _editDate = date;
      });
    }
  }

  void _assignRoute() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        // Get route name and worker name
        String? routeName;
        String? workerName;
        
        // Get route name from RouteViewModel
        final routeViewModel = Provider.of<RouteViewModel>(context, listen: false);
        final routes = routeViewModel.routes;
        final selectedRoute = routes.firstWhere(
          (route) => route.id == _selectedRouteId,
          orElse: () => RouteModel(
            id: '',
            companyId: '',
            routeName: 'Unknown Route',
            stops: [],
            status: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        routeName = selectedRoute.routeName;
        
        // Get worker name from WorkerViewModel
        final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
        final workers = workerViewModel.workers;
        final selectedWorker = workers.firstWhere(
          (worker) => worker.id == _selectedWorkerId,
          orElse: () => Worker(
            id: '',
            name: 'Unknown Worker',
            email: '',
            phone: '',
            companyId: '',
            status: '',
            poolsAssigned: 0,
            rating: 0.0,
            lastActive: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        workerName = selectedWorker.name;
        
        await _assignmentService.createAssignment(
          routeId: _selectedRouteId!,
          workerId: _selectedWorkerId!,
          routeDate: _selectedDate!,
          notes: _notesController.text,
          routeName: routeName,
          workerName: workerName,
        );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
            content: Text('Route assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedRouteId = null;
          _selectedWorkerId = null;
          _selectedDate = null;
          _notesController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign route: $e')),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
        );
    }
  }

  void _viewAssignment(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assignment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<String>(
                future: _getRouteName(assignment.routeId),
                builder: (context, snapshot) {
                  final routeName = snapshot.data ?? 'Loading...';
                  return _buildDetailRow('Route', routeName);
                },
              ),
              FutureBuilder<String>(
                future: _getWorkerName(assignment.workerId),
                builder: (context, snapshot) {
                  final workerName = snapshot.data ?? 'Loading...';
                  return _buildDetailRow('Worker', workerName);
                },
              ),
              _buildDetailRow('Date', assignment.routeDate != null 
                ? DateFormat('MMMM dd, yyyy').format(assignment.routeDate!) 
                : 'No date'),
              _buildDetailRow('Status', assignment.status.toUpperCase()),
              if (assignment.notes != null && assignment.notes!.isNotEmpty)
                _buildDetailRow('Notes', assignment.notes!),
              _buildDetailRow('Created', assignment.createdAt != null 
                ? DateFormat('MMMM dd, yyyy HH:mm').format(assignment.createdAt!) 
                : 'Unknown'),
              if (assignment.updatedAt != null)
                _buildDetailRow('Last Updated', DateFormat('MMMM dd, yyyy HH:mm').format(assignment.updatedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editAssignment(Assignment assignment) {
    // Create separate controllers for the edit dialog to avoid conflicts with main form
    final editNotesController = TextEditingController(text: assignment.notes ?? '');
    String? editWorkerId = assignment.workerId;
    String? editRouteId = assignment.routeId;
    DateTime? editDate = assignment.routeDate;
    // Normalize status to handle any case variations from database
    String editStatus;
    if (assignment.status.toLowerCase() == 'active') {
      editStatus = 'Active';
    } else if (assignment.status.toLowerCase() == 'hold') {
      editStatus = 'Hold';
    } else if (assignment.status.toLowerCase() == 'closed') {
      editStatus = 'Closed';
    } else {
      editStatus = 'Active'; // Default fallback
    }
    final editFormKey = GlobalKey<FormState>();

    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<WorkerViewModel>(
                    builder: (context, workerViewModel, child) {
                      if (workerViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Select Assignee'),
                        value: editWorkerId,
                        items: workerViewModel.workers
                            .map((worker) => DropdownMenuItem(
                                  value: worker.id,
                                  child: Text(worker.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            editWorkerId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a worker' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer<RouteViewModel>(
                    builder: (context, routeViewModel, child) {
                      if (routeViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Select Route'),
                        value: editRouteId,
                        items: routeViewModel.routes
                            .map((route) => DropdownMenuItem(
                                  value: route.id,
                                  child: Text(route.routeName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            editRouteId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a route' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Status dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: editStatus,
                    items: const [
                      DropdownMenuItem(
                        value: 'Active',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'Hold',
                        child: Text('Hold'),
                      ),
                      DropdownMenuItem(
                        value: 'Closed',
                        child: Text('Closed'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        editStatus = value!;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a status' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(editDate == null
                        ? 'Select Route Date'
                        : 'Route Date: ${DateFormat('MMMM dd, yyyy').format(editDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: editDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (date != null) {
                        setDialogState(() {
                          editDate = date;
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: editNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                editNotesController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editFormKey.currentState!.validate() && editDate != null) {
                  try {
                    // Get route name and worker name
                    String? routeName;
                    String? workerName;
                    
                    final routeViewModel = Provider.of<RouteViewModel>(context, listen: false);
                    final routes = routeViewModel.routes;
                    final selectedRoute = routes.firstWhere(
                      (route) => route.id == editRouteId,
                      orElse: () => RouteModel(
                        id: '',
                        companyId: '',
                        routeName: 'Unknown Route',
                        stops: [],
                        status: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    routeName = selectedRoute.routeName;
                    
                    final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
                    final workers = workerViewModel.workers;
                    final selectedWorker = workers.firstWhere(
                      (worker) => worker.id == editWorkerId,
                      orElse: () => Worker(
                        id: '',
                        name: 'Unknown Worker',
                        email: '',
                        phone: '',
                        companyId: '',
                        status: '',
                        poolsAssigned: 0,
                        rating: 0.0,
                        lastActive: DateTime.now(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    workerName = selectedWorker.name;
                    
                    final assignmentViewModel = Provider.of<AssignmentViewModel>(context, listen: false);
                    final success = await assignmentViewModel.updateAssignment(
                      assignment.id,
                      {
                        'routeId': editRouteId!,
                        'workerId': editWorkerId!,
                        'routeDate': editDate!,
                        'status': editStatus, // Add status to update
                        'notes': editNotesController.text,
                        'routeName': routeName,
                        'workerName': workerName,
                      },
                    );
                    
                    if (!success) {
                      throw Exception(assignmentViewModel.error ?? 'Failed to update assignment');
                    }
                    
                    editNotesController.dispose();
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assignment updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update assignment: $e')),
                    );
                  }
                } else if (editDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a date.')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 