import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/customer_repository.dart';
import 'package:shinning_pools_flutter/core/services/worker_repository.dart';
import 'package:shinning_pools_flutter/core/services/worker_invitation_repository.dart';
import 'package:shinning_pools_flutter/core/services/export_service.dart';
import 'package:shinning_pools_flutter/core/services/location_service.dart';
import 'package:shinning_pools_flutter/features/companies/models/company.dart';
import 'package:shinning_pools_flutter/features/companies/services/company_service.dart';
import 'package:shinning_pools_flutter/features/companies/viewmodels/company_notification_viewmodel.dart';
import 'package:shinning_pools_flutter/features/customers/models/customer.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customer_form_screen.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customers_list_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pool_form_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pools_list_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pool_details_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/maintenance_form_screen.dart';
import 'package:shinning_pools_flutter/features/pools/services/pool_service.dart';
import 'package:shinning_pools_flutter/features/reports/screens/reports_list_screen.dart';
import 'package:shinning_pools_flutter/features/reports/screens/issue_reports_list_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/routes_list_screen.dart';
import 'package:shinning_pools_flutter/core/services/issue_reports_service.dart';
import 'package:shinning_pools_flutter/core/services/notification_service.dart';
import 'package:shinning_pools_flutter/features/users/models/worker.dart';
import 'package:shinning_pools_flutter/features/users/models/worker_invitation.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_form_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/profile_screen.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/colors.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_background.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_button.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_card.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/company_pools_map.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/user_initials_avatar.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/location_permission_widget.dart';
import 'package:shinning_pools_flutter/features/users/viewmodels/worker_viewmodel.dart';
import 'package:shinning_pools_flutter/features/customers/viewmodels/customer_viewmodel.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/help_drawer.dart';
import '../../pools/screens/recent_company_maintenance_list.dart';
import '../../pools/screens/recent_worker_maintenance_list.dart';
import '../../pools/screens/historical_worker_maintenance_list.dart';
import '../../routes/screens/route_creation_screen.dart';
import '../../routes/screens/route_management_screen.dart';
import 'package:intl/intl.dart';
import 'package:shinning_pools_flutter/features/routes/viewmodels/assignment_viewmodel.dart';
import 'package:shinning_pools_flutter/features/routes/models/assignment.dart';
import 'package:shinning_pools_flutter/features/routes/screens/route_map_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/worker_route_map_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/today_route_map_screen.dart';
import 'package:shinning_pools_flutter/features/notifications/screens/notification_center_screen.dart';
import 'package:shinning_pools_flutter/core/models/notification.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard>
    with TickerProviderStateMixin {
  late CustomerRepository _customerRepository;
  late WorkerRepository _workerRepository;
  late CompanyService _companyService;
  late PoolService _poolService;
  late CustomerViewModel _customerViewModel;
  late WorkerViewModel _workerViewModel;
  late TabController _tabController;
  int _selectedFooterIndex = 0;
  List<Customer> _customers = [];
  List<Worker> _workers = [];
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;
  bool _isWorkerMode = false;
  bool _listenersInitialized = false;
  bool _locationPermissionGranted = false;
  bool _showLocationPermission = false;
  final LocationService _locationService = LocationService();
  final TextEditingController _poolSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Always start with 4 tabs (admin mode)
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedFooterIndex = _tabController.index;
        });
      }
    });
    _loadData();
    context.read<CompanyNotificationViewModel>().initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenersInitialized) {
      _customerRepository = context.read<CustomerRepository>();
      _workerRepository = context.read<WorkerRepository>();
      _companyService = context.read<CompanyService>();
      _poolService = context.read<PoolService>();
      _customerViewModel = context.read<CustomerViewModel>();
      _workerViewModel = context.read<WorkerViewModel>();

      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      if (currentUser?.companyId != null) {
        _poolService.initializePoolsStream(currentUser!.companyId!);
      }

      _poolService.addListener(_onPoolsChanged);
      _customerViewModel.addListener(_onCustomersChanged);
      _workerViewModel.addListener(_onWorkersChanged);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _workerViewModel.initialize();
          // Initialize AssignmentViewModel for Worker Dashboard
          final assignmentViewModel = context.read<AssignmentViewModel>();
          assignmentViewModel.loadAssignments();
        }
      });
      setState(() {
        _listenersInitialized = true;
      });
    }
  }

  void _onPoolsChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _pools = _poolService.pools;
          });
        }
      });
    }
  }

  void _onCustomersChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final customerViewModel = context.read<CustomerViewModel>();
          setState(() {
            _customers = customerViewModel.customers;
          });
        }
      });
    }
  }

  void _onWorkersChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final workerViewModel = context.read<WorkerViewModel>();
          setState(() {
            _workers = workerViewModel.workers;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (_listenersInitialized) {
      _poolService.removeListener(_onPoolsChanged);
      _customerViewModel.removeListener(_onCustomersChanged);
      _workerViewModel.removeListener(_onWorkersChanged);
    }
    _tabController.dispose();
    _poolSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser?.companyId == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
      return;
    }

    final companyId = currentUser!.companyId!;

    try {
      // Initialize customer stream through ViewModel
      final customerViewModel = context.read<CustomerViewModel>();
      await customerViewModel.initialize();

      // Initialize worker stream through ViewModel
      final workerViewModel = context.read<WorkerViewModel>();
      await workerViewModel.initialize();

      // Initialize pools stream
      _poolService.initializePoolsStream(companyId);

      // Load issue reports
      final issueReportsService = context.read<IssueReportsService>();
      try {
        await issueReportsService.loadIssueReports(companyId);
      } catch (e) {
        print('Error loading issue reports: $e');
      }

      // Small delay to allow streams to populate
      await Future.delayed(const Duration(milliseconds: 100));

      // Get current data from ViewModels
      final customers = customerViewModel.customers;
      final workers = workerViewModel.workers;
      final pools = _poolService.pools;

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            setState(() {
              _customers = customers;
              _workers = workers;
              _pools = pools;
              _isLoading = false;
            });
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isLoading = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show location permission widget if switching to worker mode and permission is not granted
    if (_showLocationPermission) {
      return LocationPermissionWidget(
        title: 'Location Access Required',
        message:
            'Worker mode requires location access to show nearby pools and optimize your routes.',
        onLocationGranted: _onLocationGranted,
        onLocationDenied: _onLocationDenied,
        showSkipOption: true,
      );
    }

    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    // ================= UI TEST: Regular AppBar for Tabbed UI =================
    PreferredSizeWidget _buildAppBar(AppUser? currentUser) {
      return AppBar(
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _isWorkerMode
                    ? 'Worker Mode - ${currentUser?.name ?? 'Admin'}'
                    : 'Welcome, ${currentUser?.name ?? 'Admin'}',
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _onProfileTapped,
              child: UserInitialsAvatar(
                displayName: currentUser?.name,
                email: currentUser?.email,
                photoUrl: currentUser?.photoUrl,
                radius: 20,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Notification button with badge
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () => _navigateToNotifications(),
                  ),
                  if (notificationService.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationService.unreadCount > 99
                              ? '99+'
                              : notificationService.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _isWorkerMode
              ? const [
                  Tab(icon: Icon(Icons.today), text: 'Today'),
                  Tab(icon: Icon(Icons.route), text: 'Routes'),
                  Tab(icon: Icon(Icons.assessment), text: 'Reports'),
                ]
              : const [
                  Tab(icon: Icon(Icons.people), text: 'Customers'),
                  Tab(icon: Icon(Icons.pool), text: 'Pools'),
                  Tab(icon: Icon(Icons.engineering), text: 'Workers'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
                ],
        ),
      );
    }
    // ================= END UI TEST =================

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(currentUser),
      drawer: const HelpDrawer(),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _isWorkerMode
                    ? [
                        // Worker Mode - Today Tab
                        _buildWorkerTodaySection(),
                        // Worker Mode - Routes Tab
                        _buildWorkerRouteSection(),
                        // Worker Mode - Reports Tab
                        _buildWorkerReportsSection(),
                      ]
                    : [
                        // Admin Mode - Customers Tab
                        ListView(
                          children: [
                            _buildNotificationSection(),
                            _buildTopStatsRow(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Customer Management'),
                            _buildManagementSectionCard(
                              title: '',
                              icon: Icons.people,
                              onTap: _navigateToCustomers,
                              onAdd: _addNewCustomer,
                              details: [
                                '${_customers.length} active customers',
                                'View customer profiles',
                                'Manage customer pools',
                              ],
                            ),
                          ],
                        ),
                        // Admin Mode - Pools Tab
                        _buildPoolsSection(),
                        // Admin Mode - Workers Tab
                        ListView(
                          children: [
                            _buildTopStatsRow(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Workers Management'),
                            _buildWorkerManagementSection(),
                          ],
                        ),
                        // Admin Mode - Reports Tab
                        ListView(
                          children: [
                            _buildTopStatsRow(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Reports & Analytics'),
                            _buildManagementSectionCard(
                              title: '',
                              icon: Icons.bar_chart,
                              onTap: _navigateToReports,
                              details: [
                                'View performance reports',
                                'Track customer satisfaction',
                                'Analyze financial data',
                              ],
                              badge: Consumer<IssueReportsService>(
                                builder: (context, issueReportsService, child) {
                                  // Check if there's an error loading data or if still loading
                                  if (issueReportsService.error != null ||
                                      issueReportsService.isLoading) {
                                    print(
                                      '🔍 Performance Reports Badge - Error detected: ${issueReportsService.error}',
                                    );
                                    print(
                                      '🔍 Performance Reports Badge - Loading: ${issueReportsService.isLoading}',
                                    );
                                    print(
                                      '🔍 Performance Reports Badge - Showing 0 due to error/loading',
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '0',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }

                                  final stats = issueReportsService
                                      .getIssueStatistics();
                                  final inProgressCount =
                                      stats['inProgress'] ?? 0;
                                  print(
                                    '🔍 Performance Reports Badge - In Progress Count: $inProgressCount',
                                  );
                                  print('🔍 Full stats: $stats');
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      inProgressCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildManagementSectionCard(
                              title: '',
                              icon: Icons.report_problem,
                              onTap: _navigateToIssueReports,
                              details: [
                                'View maintenance issues',
                                'Track issue resolution',
                                'Monitor critical problems',
                              ],
                              badge: Consumer<IssueReportsService>(
                                builder: (context, issueReportsService, child) {
                                  // Check if there's an error loading data or if still loading
                                  if (issueReportsService.error != null ||
                                      issueReportsService.isLoading) {
                                    print(
                                      '🔍 Maintenance Issues Badge - Error detected: ${issueReportsService.error}',
                                    );
                                    print(
                                      '🔍 Maintenance Issues Badge - Loading: ${issueReportsService.isLoading}',
                                    );
                                    print(
                                      '🔍 Maintenance Issues Badge - Showing 0 due to error/loading',
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '0',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }

                                  final stats = issueReportsService
                                      .getIssueStatistics();
                                  final criticalCount = stats['critical'] ?? 0;
                                  print(
                                    '🔍 Maintenance Issues Badge - Critical Count: $criticalCount',
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      criticalCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleWorkerMode,
        backgroundColor: _isWorkerMode ? AppColors.primary : Colors.orange,
        child: Icon(_isWorkerMode ? Icons.admin_panel_settings : Icons.work),
        tooltip: _isWorkerMode
            ? 'Switch to Admin Mode'
            : 'Switch to Worker Mode',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _isWorkerMode
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.today),
                  label: 'Today',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.route),
                  label: 'Routes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assessment),
                  label: 'Reports',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Customers',
                ),
                BottomNavigationBarItem(icon: Icon(Icons.pool), label: 'Pools'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.engineering),
                  label: 'Workers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
              ],
        currentIndex: _selectedFooterIndex,
        onTap: (index) {
          setState(() {
            _selectedFooterIndex = index;
            _tabController.animateTo(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Consumer<CompanyNotificationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading || viewModel.notifications.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...viewModel.notifications.map(
                (notification) =>
                    _buildNotificationCard(notification, viewModel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatsRow() {
    final int relevantWorkers = _workers
        .where(
          (w) =>
              w.status.toLowerCase() == 'active' ||
              w.status.toLowerCase() == 'available' ||
              w.status.toLowerCase() == 'on_route',
        )
        .length;

    // Get critical issues count from IssueReportsService (only unresolved issues)
    final issueReportsService = context.read<IssueReportsService>();
    final criticalIssues = issueReportsService.issueReports
        .where(
          (issue) =>
              issue.priority == 'Critical' &&
              (issue.status == 'Open' || issue.status == 'In Progress'),
        )
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSolidStatCard(
            label: 'Customers',
            value: _customers.length.toString(),
            icon: Icons.people,
            color: Colors.orange,
          ),
          _buildSolidStatCard(
            label: 'Pools',
            value: _pools.length.toString(),
            icon: Icons.pool,
            color: Colors.blue,
          ),
          _buildSolidStatCard(
            label: 'Workers',
            value: relevantWorkers.toString(),
            icon: Icons.engineering,
            color: Colors.green,
          ),
          if (criticalIssues > 0)
            _buildSolidStatCard(
              label: 'Active Critical',
              value: criticalIssues.toString(),
              icon: Icons.priority_high,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildSolidStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(59, 130, 246, 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headline.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 0, 8),
      child: Text(
        title,
        style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildNotificationCard(
    WorkerInvitation notification,
    CompanyNotificationViewModel viewModel,
  ) {
    final isAccepted = notification.status == 'accepted';
    final isRejected = notification.status == 'rejected';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isAccepted ? Icons.check_circle : Icons.cancel,
          color: isAccepted ? Colors.green : Colors.red,
        ),
        title: Text(
          isAccepted
              ? '${notification.invitedUserEmail} accepted the invitation.'
              : '${notification.invitedUserEmail} rejected the invitation.',
          style: TextStyle(
            color: isAccepted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Worker: ${notification.invitedUserEmail}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => viewModel.markAsSeen(notification.id),
        ),
      ),
    );
  }

  Widget _buildManagementSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onAdd,
    required List<String> details,
    Widget? child,
    Widget? badge,
  }) {
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (badge != null) badge,
                      if (onAdd != null)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: onAdd,
                          tooltip: 'Add New',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(left: 40, top: 4),
                      child: Text(
                        '• $detail',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildWorkerManagementSection() {
    return Consumer<WorkerViewModel>(
      builder: (context, viewModel, child) {
        return AppCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Header with navigation
              InkWell(
                onTap: _navigateToWorkers,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.engineering,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Workers Management',
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _addNewWorker,
                            tooltip: 'Invite New Worker',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• ${viewModel.totalWorkers} total workers',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '• ${viewModel.activeWorkers} active workers',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '• ${viewModel.pendingInvitations} pending invitations',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions Row - Changed to 2 columns
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Send Reminder',
                        Icons.notification_important,
                        Colors.orange,
                        () => _sendReminderToPendingInvitations(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Export Data',
                        Icons.download,
                        Colors.blue,
                        () => _exportWorkerData(),
                      ),
                    ),
                  ],
                ),
              ),

              // Second Row with Bulk Actions and Worker Reports
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Bulk Actions',
                        Icons.select_all,
                        Colors.purple,
                        () => _showBulkActionsDialog(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildWorkerReportsCard()),
                  ],
                ),
              ),

              // Worker Statistics Row
              if (viewModel.workers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildWorkerStatChip(
                        'Active',
                        viewModel.activeWorkers,
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildWorkerStatChip(
                        'On Route',
                        viewModel.onRouteWorkers,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildWorkerStatChip(
                        'Available',
                        viewModel.availableWorkers,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],

              // Worker Performance Summary
              if (viewModel.workers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Avg Rating',
                          _calculateAverageRating(viewModel.workers),
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPerformanceMetric(
                          'Avg Pools',
                          _calculateAveragePools(viewModel.workers),
                          Icons.pool,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Invitations Section
              _buildInvitationsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkerStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  String _calculateAverageRating(List<Worker> workers) {
    if (workers.isEmpty) return '0.0';
    final totalRating = workers.fold(0.0, (sum, worker) => sum + worker.rating);
    return (totalRating / workers.length).toStringAsFixed(1);
  }

  String _calculateAveragePools(List<Worker> workers) {
    if (workers.isEmpty) return '0';
    final totalPools = workers.fold(
      0,
      (sum, worker) => sum + worker.poolsAssigned,
    );
    return (totalPools / workers.length).round().toString();
  }

  Widget _buildInvitationsList() {
    return Consumer<WorkerViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Worker Invitations',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (viewModel.pendingInvitations > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${viewModel.pendingInvitations} pending',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (viewModel.invitations.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No pending invitations',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All worker invitations have been processed.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...viewModel.invitations
                        .take(3)
                        .map(
                          (inv) => GestureDetector(
                            onTap: () => _showInvitationDetails(inv),
                            child: AppCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getInvitationIcon(inv.status),
                                          color: inv.statusColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            inv.invitedUserEmail,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color.fromRGBO(
                                              59,
                                              130,
                                              246,
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Color.fromRGBO(
                                                59,
                                                130,
                                                246,
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            inv.statusDisplay,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: inv.statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sent: ${_formatDate(inv.createdAt)}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        if (inv.respondedAt != null) ...[
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.reply,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Responded: ${_formatDate(inv.respondedAt!)}',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (inv.status ==
                                        InvitationStatus.pending) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (inv.isExpired) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                  239,
                                                  68,
                                                  68,
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.warning,
                                                    size: 14,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Expired',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else if (inv.needsReminder) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                  245,
                                                  158,
                                                  11,
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .notification_important,
                                                    size: 14,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Needs Reminder',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: Colors.orange,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (inv.reminderCount > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                  59,
                                                  130,
                                                  246,
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.notifications,
                                                    size: 14,
                                                    color: Colors.blue,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${inv.reminderCount} reminder${inv.reminderCount > 1 ? 's' : ''} sent',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    if (viewModel.invitations.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.more_horiz,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${viewModel.invitations.length - 3} more invitations',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _navigateToWorkers,
                              child: Text(
                                'View All',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getInvitationIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Icons.mail_outline;
      case InvitationStatus.accepted:
        return Icons.check_circle_outline;
      case InvitationStatus.rejected:
        return Icons.cancel_outlined;
      case InvitationStatus.expired:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToWorkers() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AssociatedListScreen()));
  void _navigateToCustomers() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CustomersListScreen()));
  void _navigateToPools() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PoolsListScreen()));
  void _navigateToReports() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ReportsListScreen()));
  void _navigateToIssueReports() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const IssueReportsListScreen()));
  void _addNewCustomer() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
  void _addNewWorker() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AssociatedFormScreen()));
  void _addNewPool() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PoolFormScreen()));

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

  void _showInvitationDetails(WorkerInvitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invitation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${invitation.invitedUserEmail}'),
            Text('Status: ${invitation.statusDisplay}'),
            Text('Sent: ${_formatDate(invitation.createdAt)}'),
            if (invitation.respondedAt != null)
              Text('Responded: ${_formatDate(invitation.respondedAt!)}'),
            if (invitation.message != null && invitation.message!.isNotEmpty)
              Text('Message: ${invitation.message}'),
            const SizedBox(height: 8),
            if (invitation.reminderCount > 0) ...[
              Text('Reminders sent: ${invitation.reminderCount}'),
              if (invitation.lastReminderSentAt != null)
                Text(
                  'Last reminder: ${_formatDate(invitation.lastReminderSentAt!)}',
                ),
            ],
            if (invitation.status == InvitationStatus.pending &&
                invitation.canSendReminder) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Can send reminder',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (invitation.status == InvitationStatus.pending &&
              invitation.canSendReminder)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendIndividualReminder(invitation);
              },
              child: Text(
                'Send Reminder',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendIndividualReminder(WorkerInvitation invitation) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending reminder...'),
            ],
          ),
        ),
      );

      final invitationRepository = context.read<WorkerInvitationRepository>();
      final success = await invitationRepository.sendReminder(invitation.id);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reminder sent to ${invitation.invitedUserEmail}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send reminder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error sending reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendReminderToPendingInvitations() async {
    try {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser?.companyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No company information found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending reminders...'),
            ],
          ),
        ),
      );

      final invitationRepository = context.read<WorkerInvitationRepository>();
      final result = await invitationRepository
          .sendRemindersToPendingInvitations(currentUser!.companyId!);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result['success']) {
        final sentCount = result['sentCount'] as int;
        final totalPending = result['totalPending'] as int;
        final message = result['message'] as String;

        if (sentCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $sentCount reminders sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ℹ️ $message'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Show detailed results if there were errors
        if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
          final errors = result['errors'] as List<String>;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reminder Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Successfully sent: $sentCount'),
                  Text('📧 Total pending: $totalPending'),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '❌ Errors:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...errors.map(
                      (error) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '• $error',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error sending reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportWorkerData() async {
    try {
      // Show export format selection dialog
      final format = await ExportService.showExportFormatDialog(context);
      if (format == null) return; // User cancelled

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing export...'),
            ],
          ),
        ),
      );

      // Get current data
      final workerViewModel = context.read<WorkerViewModel>();
      final workers = workerViewModel.workers;
      final invitations = workerViewModel.invitations;

      String? result;
      if (format == 'csv') {
        result = await ExportService.exportWorkersToCSV(workers, invitations);
      } else if (format == 'json') {
        result = await ExportService.exportWorkersToJSON(workers, invitations);
      }

      // Hide loading indicator
      Navigator.of(context).pop();

      if (result != null) {
        // Show export statistics
        final stats = ExportService.getExportStats(workers, invitations);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Export completed successfully!'),
                const SizedBox(height: 16),
                Text(
                  '📊 Export Statistics:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• Total Workers: ${stats['totalWorkers']}'),
                Text('• Active Workers: ${stats['activeWorkers']}'),
                Text('• Available Workers: ${stats['availableWorkers']}'),
                Text('• On Route Workers: ${stats['onRouteWorkers']}'),
                Text('• Total Invitations: ${stats['totalInvitations']}'),
                Text('• Pending Invitations: ${stats['pendingInvitations']}'),
                Text(
                  '• Average Rating: ${stats['averageRating'].toStringAsFixed(1)}',
                ),
                Text('• Total Pools Assigned: ${stats['totalPoolsAssigned']}'),
                const SizedBox(height: 8),
                Text('Format: ${format.toUpperCase()}'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📁 File Location:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(ExportService.getFileLocationHelp()),
                      if (result != 'Web export functionality coming soon') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Path: $result',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Export completed! ${format.toUpperCase()} file ready.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Export failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error during export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Activate Selected'),
              onTap: () {
                Navigator.pop(context);
                _bulkActivateWorkers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle, color: Colors.orange),
              title: const Text('Deactivate Selected'),
              onTap: () {
                Navigator.pop(context);
                _bulkDeactivateWorkers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Selected'),
              onTap: () {
                Navigator.pop(context);
                _bulkRemoveWorkers();
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

  void _bulkActivateWorkers() {
    // TODO: Implement bulk activation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk activation coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _bulkDeactivateWorkers() {
    // TODO: Implement bulk deactivation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk deactivation coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _bulkRemoveWorkers() {
    // TODO: Implement bulk removal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk removal coming soon!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onProfileTapped() {
    if (!mounted) return;

    try {
      Navigator.of(context).pushNamed('/profile');
    } catch (e) {
      // Handle navigation errors gracefully
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
    final authService = context.read<AuthService>();
    final isAdmin =
        authService.currentUser?.role == 'admin' ||
        authService.currentUser?.role == 'root';

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
          if (isAdmin)
            AppButton(
              label: 'Route Management',
              icon: Icons.timeline,
              onPressed: _navigateToRouteManagement,
              color: Colors.blueGrey,
            ),
          const SizedBox(height: 16),
        ],
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

  void _updateStatus(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status updated to: ${status.replaceAll('_', ' ').toUpperCase()}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reportIssue() {
    _showIssueReportDialog();
  }

  void _showIssueReportDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedIssueType = 'Equipment';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.report_problem, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Report Maintenance Issue'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issue Type', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedIssueType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      [
                        'Equipment',
                        'Chemical',
                        'Water Quality',
                        'Safety',
                        'Access',
                        'Other',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    selectedIssueType = newValue!;
                  },
                ),
                const SizedBox(height: 16),
                Text('Priority', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: ['Low', 'Medium', 'High', 'Critical'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    selectedPriority = newValue!;
                  },
                ),
                const SizedBox(height: 16),
                Text('Issue Title', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief description of the issue',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Detailed Description', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide detailed information about the issue...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter an issue title'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _submitIssueReport(
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                  selectedIssueType,
                  selectedPriority,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitIssueReport(
    String title,
    String description,
    String issueType,
    String priority,
  ) async {
    try {
      final currentUser = context.read<AuthService>().currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final issueReport = {
        'title': title,
        'description': description,
        'issueType': issueType,
        'priority': priority,
        'reportedBy': currentUser.id,
        'reporterName': currentUser.name,
        'reporterEmail': currentUser.email,
        'companyId': currentUser.companyId,
        'status': 'Open',
        'reportedAt': FieldValue.serverTimestamp(),
        'location': 'Worker Dashboard',
        'deviceInfo': 'Mobile App',
      };

      // Use IssueReportsService instead of direct Firestore access
      final issueReportsService = context.read<IssueReportsService>();
      final issueId = await issueReportsService.createIssueReport(issueReport);

      if (issueId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the issue reports list
        if (currentUser.companyId != null) {
          await issueReportsService.loadIssueReports(currentUser.companyId!);
        }
      } else {
        throw Exception('Failed to create issue report');
      }

      // Log the issue report
      print('🔧 Issue Report Submitted:');
      print('  - Title: $title');
      print('  - Type: $issueType');
      print('  - Priority: $priority');
      print('  - Reporter: ${currentUser.name}');
      print('  - Company: ${currentUser.companyId}');
      print('  - Issue ID: $issueId');
    } catch (e) {
      print('❌ Error submitting issue report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _requestBreak() async {
    // Show confirmation dialog first
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.coffee, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Request Break'),
            ],
          ),
          content: Text(
            'Are you sure you want to request a break? This will notify your supervisor.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Request Break'),
            ),
          ],
        );
      },
    );

    // If user confirmed, proceed with break request
    if (confirmed == true) {
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
        final issueId = await issueReportsService.createIssueReport(
          issueReport,
        );

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

  void _requestReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review request sent to manager!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToRouteManagement() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RouteManagementScreen()));
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headline.copyWith(color: color)),
        ],
      ),
    );
  }

  void _navigateToWorkerReports() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const IssueReportsListScreen()));
  }

  Widget _buildWorkerReportsCard() {
    return Consumer<IssueReportsService>(
      builder: (context, issueReportsService, child) {
        // Use general statistics since admin should see all worker reports
        final stats = issueReportsService.getIssueStatistics();
        final activeReports =
            stats['active'] ?? 0; // Only active (unresolved) reports
        final openReports = stats['open'] ?? 0;
        final criticalReports = stats['critical'] ?? 0;

        return InkWell(
          onTap: _navigateToWorkerReports,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Worker Reports',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeReports active',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (openReports > 0)
                  Text(
                    '$openReports open',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (criticalReports > 0)
                  Text(
                    '$criticalReports critical',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
      if (mounted) {
        setState(() {
          _showLocationPermission = true;
        });
      }
    }
  }

  void _onLocationGranted() {
    setState(() {
      _locationPermissionGranted = true;
      _showLocationPermission = false;
    });
  }

  void _onLocationDenied() {
    setState(() {
      _showLocationPermission = false;
    });
    // Show a message that location is recommended
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

  void _toggleWorkerMode() async {
    // If switching to worker mode, check location permission
    if (!_isWorkerMode) {
      await _checkLocationPermission();
      if (_showLocationPermission) {
        return; // Don't switch mode yet, show location permission widget
      }
    }

    setState(() {
      _isWorkerMode = !_isWorkerMode;

      // Dispose the old controller
      _tabController.dispose();

      // Create new controller with correct number of tabs
      _tabController = TabController(
        length: _isWorkerMode ? 3 : 4,
        vsync: this,
      );

      // Add listener back
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() {
            _selectedFooterIndex = _tabController.index;
          });
        }
      });

      // Reset to first tab
      _selectedFooterIndex = 0;
    });
  }

  Widget _buildPoolsSection() {
    return ListView(
      children: [
        _buildTopStatsRow(),
        const SizedBox(height: 24),
        _buildSectionHeader('Route Management'),
        _buildManagementSectionCard(
          title: '',
          icon: Icons.route,
          onTap: _navigateToRouteManagement,
          onAdd: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RouteCreationScreen()),
            );
          },
          details: [
            'Create and manage routes',
            'Assign workers to routes',
            'Optimize pool visits',
            'Track route completion',
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Pools Management'),
        _buildManagementSectionCard(
          title: '',
          icon: Icons.pool,
          onTap: _navigateToPools,
          onAdd: _addNewPool,
          details: [
            '${_pools.length} total pools',
            'Assign pools to workers',
            'Track maintenance',
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Company Pools Map'),
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CompanyPoolsMap(
              height: 300,
              interactive: true,
              onPoolSelected: (pool) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PoolDetailsScreen(poolId: pool['id']),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const RecentCompanyMaintenanceList(),
      ],
    );
  }

  Future<void> _loadRouteForAssignment(Assignment assignment) async {
    try {
      print('🔄 Loading route data for assignment: ${assignment.routeId}');

      // Get the route data from Firestore
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(assignment.routeId)
          .get();

      if (!routeDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final routeData = routeDoc.data()!;
      final stops = routeData['stops'] ?? [];

      if (stops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pools found in this route'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('✅ Route data loaded successfully');
      print('  - Route ID: ${assignment.routeId}');
      print(
        '  - Route Name: ${assignment.routeName ?? routeData['routeName']}',
      );
      print('  - Stops: ${stops.length} pools');

      // Navigate to today route map with real route data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TodayRouteMapScreen(assignment: assignment),
        ),
      );
    } catch (e) {
      print('❌ Error loading route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAssignmentDetails(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Route Details: ${assignment.routeName ?? 'Unnamed Route'}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${assignment.formattedRouteDate}'),
            Text('Status: ${assignment.status}'),
            Text('Assigned Worker: ${assignment.workerName ?? 'Unknown'}'),
            if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes:',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(assignment.notes!),
            ],
          ],
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

  void _startMaintenanceReport(Assignment assignment) async {
    try {
      print(
        '🔄 Starting maintenance report for assignment: ${assignment.routeId}',
      );

      // Get the route data to find the first pool
      final routeDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(assignment.routeId)
          .get();

      if (!routeDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final routeData = routeDoc.data()!;
      final stops = routeData['stops'] ?? [];

      if (stops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pools found in this route'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get the first pool for maintenance report
      final firstPoolId = stops.first.toString();

      // Get pool details
      final poolDoc = await FirebaseFirestore.instance
          .collection('pools')
          .doc(firstPoolId)
          .get();

      if (!poolDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pool not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final poolData = poolDoc.data()!;
      final poolName = poolData['name'] as String? ?? 'Unknown Pool';

      // Navigate to maintenance form
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              MaintenanceFormScreen(poolId: firstPoolId, poolName: poolName),
        ),
      );
    } catch (e) {
      print('❌ Error starting maintenance report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting maintenance report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
    );
  }

  void _createTestNotification() async {
    try {
      final notificationService = context.read<NotificationService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final notificationId = await notificationService.createUserNotification(
        title: 'Test Notification',
        message: 'This is a test notification to verify the system is working.',
        recipientId: currentUser.id,
        recipientRole: currentUser.role.name,
        companyId: currentUser.companyId,
        type: NotificationType.info,
        priority: NotificationPriority.medium,
      );

      if (notificationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create test notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReportCounter(String type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getReportCounterColor(type),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getReportCounterColor(String type) {
    switch (type) {
      case 'Performance':
        return Colors.blue;
      case 'Issues':
        return Colors.red;
      case 'Financial':
        return Colors.green;
      case 'Satisfaction':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _navigateToFinancialReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial Reports coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToCustomerReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer Reports coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
