import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../users/screens/profile_screen.dart';
import '../../routes/screens/routes_list_screen.dart';
import '../../reports/screens/reports_list_screen.dart';

class AssociatedDashboard extends StatefulWidget {
  const AssociatedDashboard({super.key});

  @override
  State<AssociatedDashboard> createState() => _AssociatedDashboardState();
}

class _AssociatedDashboardState extends State<AssociatedDashboard> {
  int _selectedIndex = 0;
  String? _companyName;
  bool _didFetchCompanyName = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchCompanyName) {
      _fetchCompanyName();
      _didFetchCompanyName = true;
    }
  }

  Future<void> _fetchCompanyName() async {
    // Get the current user's companyId
    final user = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String? companyId;
    if (user != null && user['companyId'] != null) {
      companyId = user['companyId'];
    } else {
      // Try to get from Provider if available
      final authService = context.mounted ? Provider.of<AuthService>(context, listen: false) : null;
      if (authService != null && authService.currentUser != null) {
        companyId = authService.currentUser!.companyId;
      }
    }
    if (companyId == null || companyId.isEmpty) {
      debugPrint('No companyId found for worker.');
      return;
    }
    debugPrint('Fetching company with companyId: $companyId');
    final doc = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
    if (doc.exists) {
      final data = doc.data();
      debugPrint('Company document found: ${data?['name']}');
      if (data != null && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
        setState(() {
          _companyName = data['name'];
        });
      }
    } else {
      debugPrint('No company document found for companyId: $companyId');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfileTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _navigateToRoutes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoutesListScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportsListScreen()),
    );
  }

  Widget _buildTodaySection() {
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
                            '5',
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
                          'ON DUTY',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusItem('Completed', '2', Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem('Pending', '3', Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusItem('Total', '5', AppColors.primary),
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
                  Text(
                    'Today\'s Schedule',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final schedule = [
                        {'pool': 'Villa Pool #1', 'time': '09:00', 'status': 'Completed', 'color': Colors.green},
                        {'pool': 'Hotel Pool #3', 'time': '10:30', 'status': 'Completed', 'color': Colors.green},
                        {'pool': 'Residential Pool #5', 'time': '12:00', 'status': 'In Progress', 'color': Colors.blue},
                        {'pool': 'Apartment Pool #2', 'time': '14:00', 'status': 'Pending', 'color': Colors.orange},
                        {'pool': 'Office Pool #4', 'time': '16:00', 'status': 'Pending', 'color': Colors.orange},
                      ];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: schedule[index]['color'] as Color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.pool, color: Colors.white),
                        ),
                        title: Text(schedule[index]['pool'] as String),
                        subtitle: Text('${schedule[index]['time']} - ${schedule[index]['status']}'),
                        trailing: schedule[index]['status'] == 'Pending' 
                          ? IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Start maintenance coming soon!')),
                                );
                              },
                            )
                          : schedule[index]['status'] == 'In Progress'
                            ? IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Complete maintenance coming soon!')),
                                  );
                                },
                              )
                            : const Icon(Icons.check_circle, color: Colors.green),
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

  Widget _buildRouteSection() {
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
                            '12.5 km',
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
                            '6h 30m',
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
                          const SnackBar(content: Text('Route map coming soon!')),
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
                  Text(
                    'Route Stops',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final stops = [
                        {'name': 'Villa Pool #1', 'address': '123 Main St', 'time': '09:00'},
                        {'name': 'Hotel Pool #3', 'address': '456 Ocean Ave', 'time': '10:30'},
                        {'name': 'Residential Pool #5', 'address': '789 Beach Rd', 'time': '12:00'},
                        {'name': 'Apartment Pool #2', 'address': '321 Sunset Blvd', 'time': '14:00'},
                        {'name': 'Office Pool #4', 'address': '654 Business Dr', 'time': '16:00'},
                      ];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(stops[index]['name']!),
                        subtitle: Text('${stops[index]['address']} - ${stops[index]['time']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Navigation coming soon!')),
                            );
                          },
                        ),
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
            Text(
              'My Reports',
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 16),
            
            // Reports Overview
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
                            'My Reports',
                            style: AppTextStyles.subtitle,
                          ),
                          Text(
                            '3',
                            style: AppTextStyles.headline.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
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
                        child: _buildReportItem('Daily', '2', Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReportItem('Weekly', '1', Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'View All Reports',
                      onPressed: _navigateToReports,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String type, String count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(
              (color.value >> 16) & 0xFF,
              (color.value >> 8) & 0xFF,
              color.value & 0xFF,
              0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.assessment, color: color),
        ),
        const SizedBox(height: 8),
        Text(count, style: AppTextStyles.subtitle),
        Text(type, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headline.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Worker Dashboard'),
            if (_companyName != null)
              Text(
                _companyName!,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _onProfileTapped,
          ),
        ],
      ),
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
        ],
      ),
    );
  }
} 