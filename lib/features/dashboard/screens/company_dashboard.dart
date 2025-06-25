import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/customer_repository.dart';
import 'package:shinning_pools_flutter/core/services/worker_repository.dart';
import 'package:shinning_pools_flutter/features/companies/models/company.dart';
import 'package:shinning_pools_flutter/features/companies/services/company_service.dart';
import 'package:shinning_pools_flutter/features/companies/viewmodels/company_notification_viewmodel.dart';
import 'package:shinning_pools_flutter/features/customers/models/customer.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customer_form_screen.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customers_list_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pool_form_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pools_list_screen.dart';
import 'package:shinning_pools_flutter/features/reports/screens/reports_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/models/worker.dart';
import 'package:shinning_pools_flutter/features/users/models/worker_invitation.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_form_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_list_screen.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/colors.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_background.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_button.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_card.dart';
import 'package:shinning_pools_flutter/features/users/viewmodels/worker_viewmodel.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late CustomerRepository _customerRepository;
  late WorkerRepository _workerRepository;
  late CompanyService _companyService;
  List<Customer> _customers = [];
  List<Worker> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customerRepository = CustomerRepository();
    _workerRepository = WorkerRepository();
    _companyService = CompanyService();
    _loadData();
    context.read<CompanyNotificationViewModel>().initialize();
    
    // Initialize WorkerViewModel after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().initialize();
    });
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    if (currentUser?.companyId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final companyId = currentUser!.companyId!;

    try {
      final results = await Future.wait<dynamic>([
        _companyService.loadCompanyById(companyId),
        _customerRepository.getCompanyCustomers(companyId),
        _workerRepository.getCompanyWorkers(companyId),
      ]);
      
      if (mounted) {
        setState(() {
          _customers = results[1] as List<Customer>;
          _workers = results[2] as List<Worker>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  _buildSliverAppBar(currentUser?.name, currentUser?.photoUrl),
                  _buildNotificationSection(),
                  SliverToBoxAdapter(child: _buildTopStatsRow()),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildSectionHeader('Customer Management')),
                  SliverToBoxAdapter(child: _buildManagementSectionCard(
                    title: '',
                    icon: Icons.people,
                    onTap: _navigateToCustomers,
                    onAdd: _addNewCustomer,
                    details: [
                      '${_customers.length} active customers',
                      'View customer profiles',
                      'Manage customer pools'
                    ],
                  )),
                  SliverToBoxAdapter(child: _buildSectionHeader('Pools Management')),
                  SliverToBoxAdapter(child: _buildManagementSectionCard(
                    title: '',
                    icon: Icons.pool,
                    onTap: _navigateToPools,
                    onAdd: _addNewPool,
                    details: ['0 total pools', 'Assign pools to workers', 'Track maintenance'],
                  )),
                  SliverToBoxAdapter(child: _buildSectionHeader('Worker Management')),
                  SliverToBoxAdapter(child: _buildManagementSectionCard(
                    title: '',
                    icon: Icons.engineering,
                    onTap: _navigateToWorkers,
                    onAdd: _addNewWorker,
                    details: ['${_workers.length} active workers', 'Invite new workers', 'Manage worker routes'],
                    child: _buildInvitationsList(),
                  )),
                  SliverToBoxAdapter(child: _buildSectionHeader('Reports & Analytics')),
                  SliverToBoxAdapter(child: _buildManagementSectionCard(
                    title: '',
                    icon: Icons.bar_chart,
                    onTap: _navigateToReports,
                    details: ['View performance reports', 'Track customer satisfaction', 'Analyze financial data'],
                  )),
                  SliverToBoxAdapter(child: const SizedBox(height: 24)),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar(String? adminName, String? photoUrl) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      expandedHeight: 72.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
        title: Text(
          'Welcome, ${adminName ?? 'Admin'}',
          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
        ),
        background: Container(
      decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                const Color.fromRGBO(59, 130, 246, 0.7),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover))
                : const Icon(Icons.person, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return SliverToBoxAdapter(
      child: Consumer<CompanyNotificationViewModel>(
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
                      ),
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
            value: '0',
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
              color: color.withOpacity(0.2),
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

  Widget _buildInvitationsList() {
    return Consumer<WorkerViewModel>(
      builder: (context, viewModel, child) {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Worker Invitations', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
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
                Text(
                            'No invitations found.',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
                        child: ListTile(
                          leading: Icon(Icons.mail_outline, color: inv.statusColor),
                          title: Text(inv.invitedUserEmail, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${inv.statusDisplay}', style: TextStyle(color: inv.statusColor)),
                              Text('Sent: ${inv.createdAt.toLocal().toString().split(".")[0]}'),
                              if (inv.respondedAt != null)
                                Text('Responded: ${inv.respondedAt!.toLocal().toString().split(".")[0]}'),
                            ],
                          ),
                        ),
                      )),
                      if (viewModel.invitations.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... and ${viewModel.invitations.length - 3} more invitations',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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

  void _navigateToWorkers() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssociatedListScreen()));
  void _navigateToCustomers() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomersListScreen()));
  void _navigateToPools() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoolsListScreen()));
  void _navigateToReports() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsListScreen()));
  void _addNewCustomer() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
  void _addNewWorker() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssociatedFormScreen()));
  void _addNewPool() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PoolFormScreen()));
} 