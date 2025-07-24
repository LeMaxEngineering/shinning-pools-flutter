import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pool_repository.dart';
import '../../../core/services/worker_repository.dart';
import '../../../core/services/route_repository.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/issue_reports_service.dart';
import '../../../features/pools/screens/pool_details_screen.dart';
import '../../../features/pools/screens/maintenance_form_screen.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/location_permission_widget.dart';
import '../../users/screens/profile_screen.dart';
import '../../routes/screens/routes_list_screen.dart';
import '../../reports/screens/reports_list_screen.dart';
import '../../../shared/ui/widgets/user_initials_avatar.dart';
import '../../../shared/ui/widgets/help_drawer.dart';
import 'dart:async';
import '../../pools/screens/recent_worker_maintenance_list.dart';

class AssociatedDashboard extends StatefulWidget {
  const AssociatedDashboard({super.key});

  @override
  State<AssociatedDashboard> createState() => _AssociatedDashboardState();
}

class _AssociatedDashboardState extends State<AssociatedDashboard> {
  int _selectedIndex = 0;
  String? _companyName;
  bool _didFetchCompanyName = false;
  bool _isLoading = true;
  bool _locationPermissionGranted = false;
  bool _showLocationPermission = false;

  // Services
  late PoolRepository _poolRepository;
  late WorkerRepository _workerRepository;
  late RouteRepository _routeRepository;
  final LocationService _locationService = LocationService();

  // Data
  List<Map<String, dynamic>> _assignedPools = [];
  List<Map<String, dynamic>> _todayPools = [];
  List<Map<String, dynamic>> _completedPools = [];
  Map<String, dynamic>? _currentWorker;
  String _workerStatus = 'available';
  int _totalPools = 0;
  int _completedToday = 0;
  int _pendingToday = 0;
  StreamSubscription? _workerSub;
  StreamSubscription? _poolsSub;

  @override
  void initState() {
    super.initState();
    _poolRepository = PoolRepository();
    _workerRepository = WorkerRepository();
    _routeRepository = RouteRepository();
    _checkLocationPermission();
    _loadWorkerData();

    // Start listening for break request updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningForBreakRequests();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchCompanyName) {
      _fetchCompanyName();
      _didFetchCompanyName = true;
    }
  }

  @override
  void dispose() {
    _workerSub?.cancel();
    _poolsSub?.cancel();

    // Stop listening for break request updates
    final issueReportsService = context.read<IssueReportsService>();
    issueReportsService.stopListeningForBreakRequests();

    super.dispose();
  }

  Future<void> _loadWorkerData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Load worker profile
      await _loadWorkerProfile(currentUser.id);

      // Load assigned pools
      await _loadAssignedPools(currentUser.id);

      // Load today's schedule
      await _loadTodaySchedule();

      // Set up real-time listeners
      _setupRealtimeListeners(currentUser.id);
    } catch (e) {
      debugPrint('Error loading worker data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkerProfile(String workerId) async {
    try {
      final worker = await _workerRepository.getWorker(workerId);
      if (mounted) {
        setState(() {
          _currentWorker = {
            'id': worker.id,
            'name': worker.name,
            'email': worker.email,
            'phone': worker.phone,
            'status': worker.status,
            'rating': worker.rating,
            'poolsAssigned': worker.poolsAssigned,
            'lastActive': worker.lastActive,
          };
          _workerStatus = worker.status;
        });
      }
    } catch (e) {
      debugPrint('Error loading worker profile: $e');
    }
  }

  Future<void> _loadAssignedPools(String workerId) async {
    try {
      final poolsSnapshot = await _poolRepository.getWorkerPools(workerId);
      final pools = poolsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      if (mounted) {
        setState(() {
          _assignedPools = pools;
          _totalPools = pools.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading assigned pools: $e');
    }
  }

  Future<void> _loadTodaySchedule() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Filter pools for today
      final todayPools = _assignedPools.where((pool) {
        final lastMaintenance = pool['lastMaintenance'] as Timestamp?;
        if (lastMaintenance == null)
          return true; // Include pools without maintenance

        final lastMaintenanceDate = lastMaintenance.toDate();
        return lastMaintenanceDate.isBefore(todayEnd) &&
            lastMaintenanceDate.isAfter(todayStart);
      }).toList();

      // Separate completed and pending
      final completed = todayPools.where((pool) {
        final lastMaintenance = pool['lastMaintenance'] as Timestamp?;
        if (lastMaintenance == null) return false;
        final lastMaintenanceDate = lastMaintenance.toDate();
        return lastMaintenanceDate.isAfter(todayStart);
      }).toList();

      if (mounted) {
        setState(() {
          _todayPools = todayPools;
          _completedPools = completed;
          _completedToday = completed.length;
          _pendingToday = todayPools.length - completed.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading today schedule: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await _locationService.checkPermission();
      final hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (mounted) {
        setState(() {
          _locationPermissionGranted = hasPermission;
          _showLocationPermission = !hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      if (mounted) {
        setState(() {
          _showLocationPermission = true;
        });
      }
    }
  }

  void _onLocationGranted() {
    if (mounted) {
      setState(() {
        _locationPermissionGranted = true;
        _showLocationPermission = false;
      });
    }
  }

  void _onLocationDenied() {
    if (mounted) {
      setState(() {
        _showLocationPermission = false;
      });
    }
    // Show a message that location is required for optimal experience
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location access is recommended for worker functions. You can enable it later in settings.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _setupRealtimeListeners(String workerId) {
    // Listen to worker status changes
    _workerSub = _workerRepository.streamWorker(workerId).listen((worker) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentWorker = {
              'id': worker.id,
              'name': worker.name,
              'email': worker.email,
              'phone': worker.phone,
              'status': worker.status,
              'rating': worker.rating,
              'poolsAssigned': worker.poolsAssigned,
              'lastActive': worker.lastActive,
            };
            _workerStatus = worker.status;
          });
        }
      });
    });

    // Listen to assigned pools changes
    _poolsSub = _poolRepository.streamWorkerPools(workerId).listen((snapshot) {
      if (!mounted) return;
      final pools = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _assignedPools = pools;
            _totalPools = pools.length;
          });
          // Reload today's schedule when pools change
          _loadTodaySchedule();
        }
      });
    });
  }

  Future<void> _fetchCompanyName() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser?.companyId == null) {
      debugPrint('No companyId found for worker.');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(currentUser!.companyId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['name'] != null) {
          if (mounted) {
            setState(() {
              _companyName = data['name'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching company name: $e');
    }
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onProfileTapped() {
    if (!mounted) return;

    try {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToRoutes() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RoutesListScreen()));
  }

  void _navigateToReports() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportsListScreen()));
  }

  void _navigateToNewMaintenance() {
    if (!mounted) return;
    // Navigate to maintenance form without a specific pool - worker can select one
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MaintenanceFormScreen()));
  }

  void _navigateToPoolDetails(String poolId) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolDetailsScreen(poolId: poolId)),
    );
  }

  void _startMaintenance(String poolId) {
    if (!mounted) return;
    // Find the pool to get its name
    final pool = _assignedPools.firstWhere(
      (p) => p['id'] == poolId,
      orElse: () => {'name': 'Unknown Pool'},
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          poolId: poolId,
          poolName: pool['name'] ?? 'Unknown Pool',
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Work', style: AppTextStyles.headline),
            const SizedBox(height: 16),

            // Today's Overview
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned Pools', style: AppTextStyles.subtitle),
                          Text(
                            _totalPools.toString(),
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_workerStatus),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _workerStatus.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusItem(
                          'Completed',
                          _completedToday.toString(),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem(
                          'Pending',
                          _pendingToday.toString(),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem(
                          'Total',
                          _totalPools.toString(),
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Start Route',
                      onPressed: _navigateToRoutes,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Today's Schedule
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Schedule', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  if (_todayPools.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No pools scheduled for today',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayPools.length,
                      itemBuilder: (context, index) {
                        final pool = _todayPools[index];
                        final isCompleted = _completedPools.any(
                          (p) => p['id'] == pool['id'],
                        );
                        final status = isCompleted ? 'Completed' : 'Pending';
                        final color = isCompleted
                            ? Colors.green
                            : Colors.orange;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pool, color: Colors.white),
                          ),
                          title: Text(pool['name'] ?? 'Unnamed Pool'),
                          subtitle: Text(
                            '${pool['address'] ?? 'No address'} - $status',
                          ),
                          trailing: isCompleted
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () =>
                                      _startMaintenance(pool['id']),
                                ),
                          onTap: () => _navigateToPoolDetails(pool['id']),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions Section
            _buildQuickActionsSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Route', style: AppTextStyles.headline),
            const SizedBox(height: 16),

            // Route Overview
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Route Distance', style: AppTextStyles.subtitle),
                          Text(
                            '${_calculateRouteDistance().toStringAsFixed(1)} km',
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Estimated Time', style: AppTextStyles.subtitle),
                          Text(
                            _calculateEstimatedTime(),
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'View Full Route',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Route map coming soon!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Stops
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route Stops', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  if (_assignedPools.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No pools assigned to your route',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _assignedPools.length,
                      itemBuilder: (context, index) {
                        final pool = _assignedPools[index];
                        final isCompleted = _completedPools.any(
                          (p) => p['id'] == pool['id'],
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCompleted
                                ? Colors.green
                                : AppColors.primary,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(pool['name'] ?? 'Unnamed Pool'),
                          subtitle: Text(
                            '${pool['address'] ?? 'No address'} - ${isCompleted ? 'Completed' : 'Pending'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Navigation coming soon!'),
                                ),
                              );
                            },
                          ),
                          onTap: () => _navigateToPoolDetails(pool['id']),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Reports', style: AppTextStyles.headline),
            const SizedBox(height: 16),

            // Performance Overview
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance Overview', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Completion Rate',
                          '${_calculateCompletionRate()}%',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Avg Rating',
                          _currentWorker?['rating']?.toStringAsFixed(1) ??
                              '0.0',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Pools This Week',
                          _completedPools.length.toString(),
                          Icons.pool,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Hours Worked',
                          _calculateHoursWorked(),
                          Icons.timer,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reports & Actions', style: AppTextStyles.subtitle),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _navigateToReports,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'View Reports',
                          Icons.assessment,
                          Colors.blue,
                          _navigateToReports,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Export Data',
                          Icons.download,
                          Colors.green,
                          () => _exportData(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Request Review',
                          Icons.feedback,
                          Colors.orange,
                          () => _requestReview(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(height: 24),
            RecentWorkerMaintenanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Start Maintenance',
                  Icons.build,
                  Colors.green,
                  () => _navigateToNewMaintenance(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Update Status',
                  Icons.work,
                  Colors.blue,
                  () => _showStatusUpdateDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Report Issue',
                  Icons.report_problem,
                  Colors.orange,
                  () => _reportIssue(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Request Break',
                  Icons.coffee,
                  Colors.purple,
                  () => _requestBreak(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'View Map',
                  Icons.map,
                  Colors.green,
                  () => _viewMap(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Call Support',
                  Icons.phone,
                  Colors.red,
                  () => _callSupport(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _openSettings(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'Test Dialog',
                  Icons.bug_report,
                  Colors.purple,
                  () => _testBreakRequestDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container()), // Empty space
              const SizedBox(width: 12),
              Expanded(child: Container()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(59, 130, 246, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'on_route':
      case 'on route':
        return Colors.blue;
      case 'busy':
        return Colors.orange;
      case 'break':
        return Colors.purple;
      case 'off_duty':
      case 'off duty':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  double _calculateRouteDistance() {
    // Simple calculation based on number of pools
    // In a real app, this would use actual GPS coordinates
    return _assignedPools.length * 2.5; // 2.5 km per pool average
  }

  String _calculateEstimatedTime() {
    // 45 minutes per pool average
    final totalMinutes = _assignedPools.length * 45;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  int _calculateCompletionRate() {
    if (_totalPools == 0) return 0;
    return ((_completedToday / _totalPools) * 100).round();
  }

  String _calculateHoursWorked() {
    // Simple calculation - in real app would track actual hours
    return '${_completedToday * 0.75}h'; // 45 minutes per pool
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Work Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Available'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('available');
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blue),
              title: const Text('On Route'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('on_route');
              },
            ),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.orange),
              title: const Text('Busy'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('busy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.coffee, color: Colors.purple),
              title: const Text('Break'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('break');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Off Duty'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('off_duty');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) return;

      await _workerRepository.updateWorker(currentUser.id, {
        'status': status,
        'lastActive': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to: ${status.replaceAll('_', ' ').toUpperCase()}',
            ),
            backgroundColor: Colors.green,
          ),
        );
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

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue reporting coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _startListeningForBreakRequests() {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      print('🎯 Starting break request listener for worker: ${currentUser.id}');
      final issueReportsService = context.read<IssueReportsService>();
      issueReportsService.startListeningForBreakRequests(currentUser.id);
    } else {
      print('❌ No current user found for break request listener');
    }
  }

  void _showBreakRequestAuthorizedDialog(IssueReport breakRequest) {
    print('🎯 Showing break request authorized dialog for: ${breakRequest.id}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text('Break Request Authorized'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your break request has been approved!',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              if (breakRequest.resolvedByName != null) ...[
                Text(
                  'Approved by: ${breakRequest.resolvedByName}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
              ],
              if (breakRequest.resolution != null &&
                  breakRequest.resolution!.isNotEmpty) ...[
                Text(
                  'Message:',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(breakRequest.resolution!, style: AppTextStyles.body),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  // Test method to manually trigger break request dialog
  void _testBreakRequestDialog() {
    print('🎯 Testing break request dialog...');
    final testIssueReport = IssueReport(
      id: 'test-id',
      title: 'Request Break',
      description: 'Test break request',
      issueType: 'Other',
      priority: 'High',
      reportedBy: 'test-worker',
      reporterName: 'Test Worker',
      reporterEmail: 'test@example.com',
      companyId: 'test-company',
      status: 'Resolved',
      reportedAt: DateTime.now(),
      location: 'Test',
      deviceInfo: 'Test',
      resolvedBy: 'test-admin',
      resolvedByName: 'Test Admin',
      resolvedAt: DateTime.now(),
      resolution: 'Break approved for testing purposes',
    );
    _showBreakRequestAuthorizedDialog(testIssueReport);
  }

  void _requestBreak() async {
    try {
      final currentUser = context.read<AuthService>().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final issueReport = {
        'title': 'Request Break',
        'description': 'Request a break',
        'issueType': 'Other',
        'priority': 'High',
        'reportedBy': currentUser.id,
        'reporterName': currentUser.name,
        'reporterEmail': currentUser.email,
        'companyId': currentUser.companyId,
        'status': 'Open',
        'reportedAt': FieldValue.serverTimestamp(),
        'location': 'Worker Dashboard',
        'deviceInfo': 'Mobile App',
      };

      // Use IssueReportsService to create the issue report
      final issueReportsService = context.read<IssueReportsService>();
      final issueId = await issueReportsService.createIssueReport(issueReport);

      if (issueId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Break request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the issue reports list
        if (currentUser.companyId != null) {
          await issueReportsService.loadIssueReports(currentUser.companyId!);
        }
      } else {
        throw Exception('Failed to create break request');
      }

      // Log the break request
      print('☕ Break Request Submitted:');
      print('  - Title: Request Break');
      print('  - Type: Other');
      print('  - Priority: High');
      print('  - Reporter: ${currentUser.name}');
      print('  - Company: ${currentUser.companyId}');
      print('  - Issue ID: $issueId');
    } catch (e) {
      print('❌ Error submitting break request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting break request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map view coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling support...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings coming soon!'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _requestReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review request sent to manager!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show location permission widget if permission is not granted
    if (_showLocationPermission) {
      return LocationPermissionWidget(
        title: 'Location Access Required',
        message:
            'As a worker, this app needs access to your location to show nearby pools and optimize your routes.',
        onLocationGranted: _onLocationGranted,
        onLocationDenied: _onLocationDenied,
        showSkipOption: true,
      );
    }

    return Consumer<IssueReportsService>(
      builder: (context, issueReportsService, child) {
        // Check for break request authorization
        final breakRequestUpdate = issueReportsService.latestBreakRequestUpdate;
        if (breakRequestUpdate != null) {
          print(
            '🎯 Break request update detected in UI: ${breakRequestUpdate.id}',
          );
          // Clear the update to prevent showing multiple times
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🎯 Showing break request dialog...');
            issueReportsService.clearLatestBreakRequestUpdate();
            _showBreakRequestAuthorizedDialog(breakRequestUpdate);
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Worker Dashboard'),
                if (_companyName != null)
                  Text(
                    _companyName!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Builder(
                  builder: (context) {
                    final currentUser = Provider.of<AuthService>(
                      context,
                    ).currentUser;
                    return GestureDetector(
                      onTap: _onProfileTapped,
                      child: UserInitialsAvatar(
                        displayName: currentUser?.name,
                        email: currentUser?.email,
                        photoUrl: currentUser?.photoUrl,
                        radius: 20,
                        fontSize: 18,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          drawer: const HelpDrawer(),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildTodaySection(),
              _buildRouteSection(),
              _buildReportsSection(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
              BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Routes'),
              BottomNavigationBarItem(
                icon: Icon(Icons.assessment),
                label: 'Reports',
              ),
            ],
          ),
        );
      },
    );
  }
}
