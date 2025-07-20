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
import 'historical_assignment_map_screen.dart';

class AssignmentsHistoryScreen extends StatefulWidget {
  const AssignmentsHistoryScreen({super.key});

  @override
  State<AssignmentsHistoryScreen> createState() => _AssignmentsHistoryScreenState();
}

class _AssignmentsHistoryScreenState extends State<AssignmentsHistoryScreen> {
  final AssignmentService _assignmentService = AssignmentService();

  // Cache for route and worker names
  final Map<String, String> _routeNameCache = {};
  final Map<String, String> _workerNameCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<WorkerViewModel>(context, listen: false).loadWorkers();
      Provider.of<RouteViewModel>(context, listen: false).loadRoutes();
      
      // TODO: Re-enable after CORS issue is resolved
      // Check and expire routes when historical screen is accessed
      // await _assignmentService.checkAndExpireRoutes();
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
            // Purple card for the title, matching the Assign Route card style
            AppCard(
              backgroundColor: Colors.purple.shade600, // Use purple color
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historical Assignments',
                          style: AppTextStyles.headline.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View past route assignments and their completion status',
                          style: AppTextStyles.body.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoricalAssignmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalAssignmentsList() {
    return StreamBuilder<List<Assignment>>(
      stream: _assignmentService.streamAssignments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Unable to load assignments: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // This will trigger a rebuild and retry the stream
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

        // Only show historical assignments (using isHistorical property)
        final historicalAssignments = snapshot.data!
            .where((a) => a.isHistorical)
            .map((assignment) {
          if (assignment.status.toUpperCase() == 'ACTIVE') {
            // Create a new Assignment instance with the status changed to 'EXPIRED'
            return Assignment(
              id: assignment.id,
              routeId: assignment.routeId,
              workerId: assignment.workerId,
              routeName: assignment.routeName,
              workerName: assignment.workerName,
              assignedAt: assignment.assignedAt,
              routeDate: assignment.routeDate,
              status: 'EXPIRED', // The new status
              companyId: assignment.companyId,
              notes: assignment.notes,
              createdAt: assignment.createdAt,
              updatedAt: assignment.updatedAt,
            );
          }
          return assignment;
        }).toList();
        
        historicalAssignments.sort((a, b) => b.routeDate!.compareTo(a.routeDate!));

        if (historicalAssignments.isEmpty) {
          return const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No historical assignments found.'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historicalAssignments.length,
          itemBuilder: (context, index) {
            final assignment = historicalAssignments[index];
            return InkWell(
              onTap: () => _showAssignmentMap(assignment),
              child: AppCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                backgroundColor: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history,
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                    // Map button for historical assignments
                    IconButton(
                      onPressed: () => _showAssignmentMap(assignment),
                      icon: const Icon(Icons.map, color: Colors.white),
                      tooltip: 'View Route Map',
                    ),
                    // View button for historical assignments (read-only)
                    IconButton(
                      onPressed: () => _viewAssignment(assignment),
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      tooltip: 'View Details',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignmentMap(Assignment assignment) {
    final routeDate = assignment.routeDate;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricalAssignmentMapScreen(
          assignment: assignment,
          routeDate: routeDate,
        ),
      ),
    );
  }

  void _viewAssignment(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historical Assignment Details'),
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
              if (assignment.assignedAt != null)
                _buildDetailRow('Assigned At', DateFormat('MMMM dd, yyyy HH:mm').format(assignment.assignedAt!)),
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