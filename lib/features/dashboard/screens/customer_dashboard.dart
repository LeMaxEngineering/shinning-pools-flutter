import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/worker_invitation_repository.dart';
import 'package:shinning_pools_flutter/features/users/models/worker_invitation.dart';
import 'package:shinning_pools_flutter/features/users/screens/invitation_notification_screen.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_background.dart';
import '../../users/screens/profile_screen.dart';
import '../../pools/screens/pools_list_screen.dart';
import '../../../shared/ui/widgets/user_initials_avatar.dart';
import '../../../shared/ui/widgets/help_drawer.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String name, String? photoUrl) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Welcome, $name',
          style: AppTextStyles.subtitle.copyWith(color: Colors.white),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              const Text('No new notifications'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to Shinning Pools', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text('Manage your pools and track maintenance', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Services', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            const Text('Pool maintenance services available'),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maintenance', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            const Text('Track your pool maintenance history'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
          );
        }

    final showCompanyRegistrationFooter = authService.currentUser != null &&
        authService.currentUser!.companyId == null &&
        !authService.currentUser!.pendingCompanyRequest;
        
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/img/icon.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Customer Dashboard',
              style: AppTextStyles.subtitle.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotificationsDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _onProfileTapped,
              child: UserInitialsAvatar(
                displayName: currentUser?.name,
                email: currentUser?.email,
                photoUrl: currentUser?.photoUrl,
                radius: 20,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      drawer: const HelpDrawer(),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMyPoolsSection(),
          _buildReportsSection(),
        ],
              ),
      ),
      bottomNavigationBar: showCompanyRegistrationFooter
          ? _buildCompanyRegistrationFooter()
          : BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.pool),
                  label: 'My Pools',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.primary,
              onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildMyPoolsSection() {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const AppCard(child: Text('User not authenticated.'));
    }

    // If no invitation, proceed with existing logic
    if (currentUser.pendingCompanyRequest) {
      return _buildPendingCompanyStatus();
    }

    // Restore: Show invitation card if there is a pending worker invitation
    return StreamBuilder<List<WorkerInvitation>>(
      stream: WorkerInvitationRepository().streamUserInvitations(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final invitations = snapshot.data ?? [];
        if (invitations.isNotEmpty) {
          // Show the first pending invitation
          return _buildInvitationCard(invitations.first);
        }
        // No invitation, show pools/registration logic
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pools')
            .where('customerId', isEqualTo: currentUser.id)
            .snapshots(),
      builder: (context, poolSnapshot) {
        if (poolSnapshot.hasData && poolSnapshot.data!.docs.isNotEmpty) {
          // User has pools, show pool management card
          return _buildPoolManagementCard(poolSnapshot.data!.docs.length);
        }
        // User has no pools, show registration options
        return _buildRegistrationOptions();
          },
        );
      },
    );
  }

  Widget _buildReportsSection() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: AppCard(child: Text('Reports Section')),
    );
  }

  Widget _buildInvitationCard(WorkerInvitation invitation) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: AppCard(
          backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'You Have a New Invitation!',
                style: AppTextStyles.headline.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${invitation.companyName} has invited you to join their team as a worker.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'View Invitation',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvitationNotificationScreen(invitation: invitation),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoolManagementCard(int poolCount) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Pools', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                  const SizedBox(height: 16),
                  AppCard(
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Pools', style: AppTextStyles.subtitle),
                        Text('$poolCount', style: AppTextStyles.headline.copyWith(color: AppColors.primary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('INDEPENDENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You can continue managing your pools independently.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Manage Your Pools',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/poolsList');
                            },
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Register New Pool',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/poolForm');
                            },
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

  Widget _buildRegistrationOptions() {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome!', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                
                // Card for registering a pool
                AppCard(
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register Your Pool',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your pool maintenance independently.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Register a New Pool',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/poolForm');
                          },
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Card for registering a company
                AppCard(
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you a Pool Company?',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register your company to manage clients, routes, and reports.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Register Your Company',
                          onPressed: () {
                            Navigator.of(context).pushNamed('/companyRegistration');
                          },
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyRegistrationFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Solid white background
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Want to register your company?',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join our network of pool service companies and expand your business.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Register Company',
              onPressed: () {
                Navigator.of(context).pushNamed('/companyRegistration');
              },
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCompanyStatus() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
      child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
                Icon(Icons.hourglass_top, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Registration Pending',
                  style: AppTextStyles.headline,
            ),
                SizedBox(height: 8),
            Text(
                  'Your company registration is currently under review by our team. We will notify you once it is approved.',
              textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
            ),
              ],
            ),
            ),
        ),
      ),
    );
  }
}