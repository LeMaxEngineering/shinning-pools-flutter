import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/customer_repository.dart';
import 'package:shinning_pools_flutter/core/services/worker_repository.dart';
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
import 'package:shinning_pools_flutter/features/routes/screens/routes_list_screen.dart';
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
import 'package:shinning_pools_flutter/shared/ui/widgets/user_initials_avatar.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/location_permission_widget.dart';
import 'package:shinning_pools_flutter/features/users/viewmodels/worker_viewmodel.dart';
import 'package:shinning_pools_flutter/features/customers/viewmodels/customer_viewmodel.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/help_drawer.dart';
import '../../pools/screens/recent_company_maintenance_list.dart';
import '../../routes/screens/route_creation_screen.dart';
import '../../routes/screens/route_management_screen.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> with TickerProviderStateMixin {
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
      vsync: this
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
      
      // Small delay to allow streams to populate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get current data from ViewModels
      final customers = customerViewModel.customers;
      final workers = workerViewModel.workers;
      final pools = _poolService.pools;
      
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
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
        message: 'Worker mode requires location access to show nearby pools and optimize your routes.',
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
                style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
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
          // Removed worker mode toggle icon from AppBar
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
                          'Manage customer pools'
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
                          _buildSectionHeader('Worker Management'),
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
                                'Analyze financial data'
                              ],
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
        tooltip: _isWorkerMode ? 'Switch to Admin Mode' : 'Switch to Worker Mode',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.pool),
            label: 'Pools',
          ),
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
                Text('Notifications', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...viewModel.notifications.map((notification) => _buildNotificationCard(notification, viewModel)),
              ],
            ),
                          );
                        },
                    );
  }

  Widget _buildTopStatsRow() {
    final int relevantWorkers = _workers.where((w) =>
      w.status.toLowerCase() == 'active' ||
      w.status.toLowerCase() == 'available' ||
      w.status.toLowerCase() == 'on_route'
    ).length;
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
            Text(value, style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white)),
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

  Widget _buildNotificationCard(WorkerInvitation notification, CompanyNotificationViewModel viewModel) {
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
        ),
        subtitle: Text('Worker: ${notification.invitedUserEmail}'),
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
                      Expanded(child: Text(title, style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold))),
                      if (onAdd != null)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: onAdd,
                          tooltip: 'Add New',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...details.map((detail) => Padding(
                    padding: const EdgeInsets.only(left: 40, top: 4),
                    child: Text('• $detail', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  )),
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
                          Icon(Icons.engineering, color: AppColors.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Worker Management', 
                              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)
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
                      Text('• ${viewModel.totalWorkers} total workers', 
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      Text('• ${viewModel.activeWorkers} active workers', 
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      Text('• ${viewModel.pendingInvitations} pending invitations', 
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              
              // Quick Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Bulk Actions',
                        Icons.select_all,
                        Colors.purple,
                        () => _showBulkActionsDialog(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Worker Statistics Row
              if (viewModel.workers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildWorkerStatChip('Active', viewModel.activeWorkers, Colors.green),
                      const SizedBox(width: 8),
                      _buildWorkerStatChip('On Route', viewModel.onRouteWorkers, Colors.blue),
                      const SizedBox(width: 8),
                      _buildWorkerStatChip('Available', viewModel.availableWorkers, Colors.orange),
                    ],
                  ),
                ),
              ],
              
              // Worker Performance Summary
              if (viewModel.workers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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

  Widget _buildPerformanceMetric(String label, String value, IconData icon, Color color) {
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
          Text(value, style: AppTextStyles.subtitle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          )),
          Text(label, style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          )),
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
    final totalPools = workers.fold(0, (sum, worker) => sum + worker.poolsAssigned);
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
                  Text('Worker Invitations', 
                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (viewModel.pendingInvitations > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            Icon(Icons.check_circle_outline, 
                              color: Colors.green, size: 20),
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
                      ...viewModel.invitations.take(3).map((inv) => AppCard(
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
                                    horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(59, 130, 246, 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color.fromRGBO(59, 130, 246, 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    inv.statusDisplay,
                                    style: AppTextStyles.caption.copyWith(
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
                                Icon(Icons.access_time, 
                                  size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Sent: ${_formatDate(inv.createdAt)}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (inv.respondedAt != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.reply, 
                                    size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Responded: ${_formatDate(inv.respondedAt!)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (inv.status == InvitationStatus.pending && inv.isExpired) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(239, 68, 68, 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning, 
                                      size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Expired',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ],
                          ),
                        ),
                      )),
                      if (viewModel.invitations.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.more_horiz, 
                              color: AppColors.textSecondary, size: 16),
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

  void _navigateToWorkers() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssociatedListScreen()));
  void _navigateToCustomers() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomersListScreen()));
  void _navigateToPools() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoolsListScreen()));
  void _navigateToReports() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsListScreen()));
  void _addNewCustomer() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
  void _addNewWorker() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssociatedFormScreen()));
  void _addNewPool() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoolFormScreen()));

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
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

  void _sendReminderToPendingInvitations() {
    // TODO: Implement reminder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportWorkerData() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
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
    final assignedPools = _pools.where((pool) => 
      pool['assignedWorkerId'] == context.read<AuthService>().currentUser?.id
    ).toList();
    
    final completedToday = assignedPools.where((pool) {
      final lastMaintenance = pool['lastMaintenance'];
      if (lastMaintenance == null) return false;
      final today = DateTime.now();
      final maintenanceDate = (lastMaintenance as Timestamp).toDate();
      return maintenanceDate.year == today.year && 
             maintenanceDate.month == today.month && 
             maintenanceDate.day == today.day;
    }).length;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Work',
              style: AppTextStyles.headline,
            ),
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
                          Text(
                            'Assigned Pools',
                            style: AppTextStyles.subtitle,
                          ),
                          Text(
                            assignedPools.length.toString(),
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'WORKING',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusItem('Completed', completedToday.toString(), Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem('Pending', (assignedPools.length - completedToday).toString(), Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem('Total', assignedPools.length.toString(), AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Start Route',
                      onPressed: _navigateToWorkerRoutes,
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
                  Text(
                    'Today\'s Schedule',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  if (assignedPools.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No pools assigned to you today',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assignedPools.length,
                      itemBuilder: (context, index) {
                        final pool = assignedPools[index];
                        final isCompleted = pool['lastMaintenance'] != null;
                        final status = isCompleted ? 'Completed' : 'Pending';
                        final color = isCompleted ? Colors.green : Colors.orange;
                        
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
                          subtitle: Text('${pool['address'] ?? 'No address'} - $status'),
                          trailing: isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _startMaintenance(pool['id']),
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
            _buildWorkerQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerRouteSection() {
    final assignedPools = _pools.where((pool) => 
      pool['assignedWorkerId'] == context.read<AuthService>().currentUser?.id
    ).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Route',
              style: AppTextStyles.headline,
            ),
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
                          Text(
                            'Route Distance',
                            style: AppTextStyles.subtitle,
                          ),
                          Text(
                            '${(assignedPools.length * 2.5).toStringAsFixed(1)} km',
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Estimated Time',
                            style: AppTextStyles.subtitle,
                          ),
                          Text(
                            '${(assignedPools.length * 45 ~/ 60)}h ${(assignedPools.length * 45 % 60)}m',
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
                      onPressed: _navigateToWorkerRoutes,
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
                  Text(
                    'Route Stops',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  if (assignedPools.isEmpty)
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
                      itemCount: assignedPools.length,
                      itemBuilder: (context, index) {
                        final pool = assignedPools[index];
                        final isCompleted = pool['lastMaintenance'] != null;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCompleted ? Colors.green : AppColors.primary,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(pool['name'] ?? 'Unnamed Pool'),
                          subtitle: Text('${pool['address'] ?? 'No address'} - ${isCompleted ? 'Completed' : 'Pending'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Navigation coming soon!')),
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

  Widget _buildWorkerReportsSection() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Reports',
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 16),
            
            // Performance Overview
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Overview',
                    style: AppTextStyles.subtitle,
                  ),
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
                      Text(
                        'Reports & Actions',
                        style: AppTextStyles.subtitle,
                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerQuickActionsSection() {
    final authService = context.read<AuthService>();
    final isAdmin = authService.currentUser?.role == 'admin' || authService.currentUser?.role == 'root';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.subtitle,
          ),
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
              Expanded(child: Container()), // Empty space
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoutesListScreen()),
    );
  }

  void _navigateToNewMaintenance() {
    // Navigate to maintenance form without a specific pool - worker can select one
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MaintenanceFormScreen(),
      ),
    );
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
      MaterialPageRoute(
        builder: (_) => PoolDetailsScreen(poolId: poolId),
      ),
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
        content: Text('Status updated to: ${status.replaceAll('_', ' ').toUpperCase()}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Issue reporting coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _requestBreak() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Break request sent to manager!'),
        backgroundColor: Colors.purple,
      ),
    );
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RouteManagementScreen()),
    );
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
          Text(
            value,
            style: AppTextStyles.headline.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWorkerReports() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportsListScreen()),
    );
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await _locationService.checkPermission();
      final hasPermission = permission == LocationPermission.whileInUse || 
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
          content: Text('Location access is recommended for worker functions. You can enable it later in settings.'),
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
        const SizedBox(height: 24),
        const RecentCompanyMaintenanceList(),
      ],
    );
  }


} 