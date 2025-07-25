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
import '../../pools/screens/recent_worker_maintenance_list.dart';
import '../../pools/screens/historical_worker_maintenance_list.dart';
import '../../routes/viewmodels/assignment_viewmodel.dart';
import '../../routes/models/assignment.dart';
import 'package:intl/intl.dart';

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
  bool _disposed = false;

  // Services
  late PoolRepository _poolRepository;
  late WorkerRepository _workerRepository;
  late RouteRepository _routeRepository;
  final LocationService _locationService = LocationService();

  // Data
  List<Map<String, dynamic>> _pools = [];

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
    _disposed = true;
    // Stop listening for break request updates
    final issueReportsService = context.read<IssueReportsService>();
    issueReportsService.stopListeningForBreakRequests();

    super.dispose();
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Method to show assignment details
  void _showAssignmentDetails(Assignment assignment) {
    // TODO: Implement assignment details dialog
    print('Show assignment details for: ${assignment.routeName}');
  }

  // Method to load route for assignment
  void _loadRouteForAssignment(Assignment assignment) {
    // TODO: Implement route loading
    print('Load route for assignment: ${assignment.routeName}');
  }

  // Method to start listening for break requests
  void _startListeningForBreakRequests() {
    final issueReportsService = context.read<IssueReportsService>();
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      issueReportsService.startListeningForBreakRequests(currentUser.id);
    }
  }

  // Method to show break request authorized dialog
  void _showBreakRequestAuthorizedDialog(IssueReport breakRequest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Break Request Authorized'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your break request has been approved!'),
            SizedBox(height: 8),
            if (breakRequest.resolvedByName != null)
              Text('Approved by: ${breakRequest.resolvedByName}'),
            if (breakRequest.resolution != null &&
                breakRequest.resolution!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Message: ${breakRequest.resolution}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWorkerData() async {
    if (_disposed) return;

    try {
      setState(() => _isLoading = true);

      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        if (mounted && !_disposed) setState(() => _isLoading = false);
        return;
      }

      // Load assigned pools
      await _loadAssignedPools(currentUser.id);
    } catch (e) {
      debugPrint('Error loading worker data: $e');
    } finally {
      if (mounted && !_disposed) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignedPools(String workerId) async {
    if (_disposed) return;

    try {
      final poolsSnapshot = await _poolRepository.getWorkerPools(workerId);
      final pools = poolsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      if (mounted && !_disposed) {
        setState(() {
          _pools = pools;
        });
      }
    } catch (e) {
      debugPrint('Error loading assigned pools: $e');
    }
  }

  Future<void> _fetchCompanyName() async {
    if (_disposed) return;

    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser?.companyId != null) {
        final companyDoc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(currentUser!.companyId)
            .get();

        if (companyDoc.exists) {
          final companyData = companyDoc.data()!;
          if (mounted && !_disposed) {
            setState(() {
              _companyName = companyData['name'] as String?;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching company name: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    if (_disposed) return;

    try {
      final permission = await _locationService.checkPermission();
      if (mounted && !_disposed) {
        setState(() {
          _locationPermissionGranted =
              permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
          _showLocationPermission = !_locationPermissionGranted;
        });
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  void _onLocationGranted() {
    if (mounted && !_disposed) {
      setState(() {
        _locationPermissionGranted = true;
        _showLocationPermission = false;
      });
    }
  }

  void _onLocationDenied() {
    if (mounted && !_disposed) {
      setState(() {
        _locationPermissionGranted = false;
        _showLocationPermission = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (mounted && !_disposed) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onProfileTapped() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
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
              _buildWorkerTodaySection(),
              _buildWorkerRouteSection(),
              _buildWorkerReportsSection(),
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

  // Worker mode section methods - Full implementations
  Widget _buildWorkerTodaySection() {
    return Consumer<AssignmentViewModel>(
      builder: (context, assignmentViewModel, child) {
        if (assignmentViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = assignmentViewModel.assignments;
        final currentUser = context.read<AuthService>().currentUser;

        print('🔍 Worker Dashboard Debug:');
        print('  - Total assignments loaded: ${assignments.length}');
        print('  - Current User ID: ${currentUser?.id}');

        // Filter assignments to only show those assigned to the current user
        final personalAssignments = assignments.where((assignment) {
          return assignment.workerId == currentUser?.id;
        }).toList();

        print('  - Personal assignments: ${personalAssignments.length}');

        for (int i = 0; i < personalAssignments.length; i++) {
          final assignment = personalAssignments[i];
          print('  - Personal Assignment $i:');
          print('    ID: ${assignment.id}');
          print('    Route Name: ${assignment.routeName}');
          print('    Status: ${assignment.status}');
          print('    Is Historical: ${assignment.isHistorical}');
          print('    Route Date: ${assignment.routeDate?.toIso8601String()}');
        }

        // Filter for active assignments (not historical) and exclude test routes
        final activeAssignments = personalAssignments
            .where(
              (a) =>
                  !a.isHistorical &&
                  a.status == 'Active' &&
                  !(a.routeName?.contains('Test Route for Worker') ?? false) &&
                  // Only show assignments for today's date
                  _isSameDay(a.routeDate ?? DateTime.now(), DateTime.now()),
            )
            .toList();

        print(
          '  - Active assignments after filtering: ${activeAssignments.length}',
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s Work', style: AppTextStyles.headline),
                const SizedBox(height: 16),

                // Today's Assignments
                if (activeAssignments.isNotEmpty) ...[
                  Text('Today\'s Assignments', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeAssignments.length,
                    itemBuilder: (context, index) {
                      final assignment = activeAssignments[index];
                      final routeDate = assignment.routeDate ?? DateTime.now();
                      final formattedDate = DateFormat(
                        'MMMM dd, yyyy',
                      ).format(routeDate);

                      // Calculate mock distance and time based on route ID
                      final routeIdHash = assignment.routeId.hashCode;
                      final distance = 5.0 + (routeIdHash % 5); // 5.0 to 9.9 km
                      final timeMinutes =
                          90 + (routeIdHash % 60); // 90 to 149 minutes
                      final hours = timeMinutes ~/ 60;
                      final minutes = timeMinutes % 60;
                      final poolCount = 2 + (routeIdHash % 3); // 2 to 4 pools

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.routeName ?? 'Unnamed Route',
                                        style: AppTextStyles.headline.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    assignment.status,
                                    style: AppTextStyles.body.copyWith(
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
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${distance.toStringAsFixed(1)} km',
                                        style: AppTextStyles.headline.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Route Distance',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${hours}h ${minutes}m',
                                        style: AppTextStyles.headline.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Estimated Time',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Flexible(
                                  child: AppButton(
                                    label: 'Route Information',
                                    onPressed: () =>
                                        _showAssignmentDetails(assignment),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Execute Active Route',
                                    onPressed: () =>
                                        _loadRouteForAssignment(assignment),
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Active Routes',
                              style: AppTextStyles.subtitle.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You don\'t have any active route assignments today.',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Debug: Found ${assignments.length} total, ${personalAssignments.length} personal',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Quick Actions Section
                _buildWorkerQuickActionsSection(),
                const SizedBox(height: 16),

                // Recent Maintenance List Section
                const RecentWorkerMaintenanceList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkerRouteSection() {
    return Consumer<AssignmentViewModel>(
      builder: (context, assignmentViewModel, child) {
        if (assignmentViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = assignmentViewModel.assignments;
        final currentUser = context.read<AuthService>().currentUser;

        print('🔍 Worker Routes Debug:');
        print('  - Total assignments loaded: ${assignments.length}');
        print('  - Current User ID: ${currentUser?.id}');

        // Filter assignments to only show those assigned to the current user
        final personalAssignments = assignments.where((assignment) {
          return assignment.workerId == currentUser?.id;
        }).toList();

        print('  - Personal assignments: ${personalAssignments.length}');

        // Filter for active assignments (not historical) and exclude test routes
        final activeAssignments = personalAssignments
            .where(
              (a) =>
                  !a.isHistorical &&
                  a.status == 'Active' &&
                  !(a.routeName?.contains('Test Route for Worker') ?? false),
            )
            .toList();

        print('  - Active assignments: ${activeAssignments.length}');

        if (activeAssignments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Active Routes', style: AppTextStyles.headline),
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Active Routes',
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any active route assignments.',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Debug: Found ${assignments.length} total, ${personalAssignments.length} personal',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Active Routes', style: AppTextStyles.headline),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: activeAssignments.length,
                  itemBuilder: (context, index) {
                    final assignment = activeAssignments[index];
                    final routeDate = assignment.routeDate ?? DateTime.now();
                    final formattedDate = DateFormat(
                      'MMMM dd, yyyy',
                    ).format(routeDate);

                    // Calculate mock distance and time based on route ID
                    final routeIdHash = assignment.routeId.hashCode;
                    final distance = 5.0 + (routeIdHash % 5); // 5.0 to 9.9 km
                    final timeMinutes =
                        90 + (routeIdHash % 60); // 90 to 149 minutes
                    final hours = timeMinutes ~/ 60;
                    final minutes = timeMinutes % 60;
                    final poolCount = 2 + (routeIdHash % 3); // 2 to 4 pools

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment.routeName ?? 'Unnamed Route',
                                      style: AppTextStyles.headline.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  assignment.status,
                                  style: AppTextStyles.body.copyWith(
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
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${distance.toStringAsFixed(1)} km',
                                      style: AppTextStyles.headline.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Route Distance',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${hours}h ${minutes}m',
                                      style: AppTextStyles.headline.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Estimated Time',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Flexible(
                                child: AppButton(
                                  label: 'View Route Map',
                                  onPressed: () =>
                                      _loadRouteForAssignment(assignment),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: AppButton(
                                  label: 'View Pools ($poolCount)',
                                  onPressed: () =>
                                      _showAssignmentDetails(assignment),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Start Maintenance Report',
                                  onPressed: () =>
                                      _startMaintenanceReport(assignment),
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkerReportsSection() {
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
                          '85%',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Avg Rating',
                          '4.8',
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
                          _pools.length.toString(),
                          Icons.pool,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Hours Worked',
                          '${(_pools.length * 0.75).toStringAsFixed(1)}h',
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
                        onPressed: _navigateToWorkerReports,
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
                          _navigateToWorkerReports,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Export Data',
                          Icons.download,
                          Colors.green,
                          () => _exportWorkerData(),
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
            const SizedBox(height: 16),

            // Historical Maintenance List Section
            const HistoricalWorkerMaintenanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerQuickActionsSection() {
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
                  'Test Notification',
                  Icons.notifications,
                  Colors.amber,
                  () => _createTestNotification(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Container()), // Empty space
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildPerformanceMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.05),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(59, 130, 246, 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
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

  // Worker mode helper methods
  void _navigateToWorkerRoutes() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RoutesListScreen()));
  }

  void _navigateToNewMaintenance() {
    // Navigate to maintenance form without a specific pool - worker can select one
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MaintenanceFormScreen()));
  }

  void _startMaintenance(String poolId) {
    // Find the pool to get its name
    final pool = _pools.firstWhere(
      (p) => p['id'] == poolId,
      orElse: () => {'name': 'Unknown Pool'},
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceFormScreen(
          poolId: poolId,
          poolName: pool['name'] ?? 'Unknown Pool',
        ),
      ),
    );
  }

  void _navigateToPoolDetails(String poolId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PoolDetailsScreen(poolId: poolId)),
    );
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

      await _workerRepository.updateWorkerStatus(currentUser.id, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
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
    // TODO: Implement issue reporting
    print('Report issue');
  }

  void _requestBreak() async {
    // TODO: Implement break request
    print('Request break');
  }

  void _viewMap() {
    // TODO: Implement map view
    print('View map');
  }

  void _callSupport() {
    // TODO: Implement support call
    print('Call support');
  }

  void _openSettings() {
    // TODO: Implement settings
    print('Open settings');
  }

  void _navigateToWorkerReports() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportsListScreen()));
  }

  void _exportWorkerData() {
    // TODO: Implement data export
    print('Export worker data');
  }

  void _requestReview() {
    // TODO: Implement review request
    print('Request review');
  }

  void _startMaintenanceReport(Assignment assignment) {
    // TODO: Implement maintenance report
    print('Start maintenance report for assignment: ${assignment.routeName}');
  }

  void _createTestNotification() async {
    try {
      // TODO: Implement test notification creation
      print('Create test notification');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
