import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'route_details_screen.dart';

class RoutesListScreen extends StatefulWidget {
  const RoutesListScreen({super.key});

  @override
  State<RoutesListScreen> createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  final List<Map<String, dynamic>> _routes = [
    {
      'id': '1',
      'name': 'Morning Route - Downtown',
      'date': '2024-01-15',
      'status': 'In Progress',
      'worker': 'John Smith',
      'pools': [
        {'name': 'Hotel Marina Pool', 'status': 'Completed', 'time': '08:30'},
        {'name': 'Apartment Complex Pool', 'status': 'In Progress', 'time': '10:15'},
        {'name': 'Office Building Pool', 'status': 'Pending', 'time': '11:45'},
      ],
      'totalPools': 3,
      'completedPools': 1,
      'estimatedDuration': '4 hours',
      'actualDuration': '2 hours 30 min',
      'notes': 'Traffic was light this morning',
    },
    {
      'id': '2',
      'name': 'Afternoon Route - Beach Area',
      'date': '2024-01-15',
      'status': 'Scheduled',
      'worker': 'John Smith',
      'pools': [
        {'name': 'Beach Resort Pool', 'status': 'Pending', 'time': '14:00'},
        {'name': 'Private Villa Pool', 'status': 'Pending', 'time': '15:30'},
        {'name': 'Hotel Oceanview Pool', 'status': 'Pending', 'time': '17:00'},
      ],
      'totalPools': 3,
      'completedPools': 0,
      'estimatedDuration': '3 hours',
      'actualDuration': null,
      'notes': '',
    },
    {
      'id': '3',
      'name': 'Evening Route - Suburbs',
      'date': '2024-01-14',
      'status': 'Completed',
      'worker': 'John Smith',
      'pools': [
        {'name': 'Residential Pool A', 'status': 'Completed', 'time': '18:00'},
        {'name': 'Residential Pool B', 'status': 'Completed', 'time': '19:15'},
        {'name': 'Community Pool', 'status': 'Completed', 'time': '20:30'},
      ],
      'totalPools': 3,
      'completedPools': 3,
      'estimatedDuration': '2.5 hours',
      'actualDuration': '2 hours 45 min',
      'notes': 'All pools in excellent condition',
    },
  ];

  String _selectedDate = '2024-01-15';
  String _statusFilter = 'All';

  List<Map<String, dynamic>> get _filteredRoutes {
    return _routes.where((route) {
      final matchesDate = route['date'] == _selectedDate;
      final matchesStatus = _statusFilter == 'All' || route['status'] == _statusFilter;
      return matchesDate && matchesStatus;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Scheduled':
        return Colors.blue;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPoolStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.grey;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _viewRouteDetails(Map<String, dynamic> route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(route: route),
      ),
    );
  }

  void _startRoute(Map<String, dynamic> route) {
    setState(() {
      final index = _routes.indexWhere((r) => r['id'] == route['id']);
      if (index != -1) {
        _routes[index]['status'] = 'In Progress';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started route: ${route['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _completeRoute(Map<String, dynamic> route) {
    setState(() {
      final index = _routes.indexWhere((r) => r['id'] == route['id']);
      if (index != -1) {
        _routes[index]['status'] = 'Completed';
        _routes[index]['actualDuration'] = '3 hours 15 min';
        _routes[index]['completedPools'] = _routes[index]['totalPools'];
        
        // Mark all pools as completed
        for (var pool in _routes[index]['pools']) {
          pool['status'] = 'Completed';
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed route: ${route['name']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.parse(_selectedDate),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              ).then((date) {
                if (date != null) {
                  setState(() {
                    _selectedDate = date.toIso8601String().split('T')[0];
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date Display
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selected Date', style: AppTextStyles.caption),
                            Text(
                              DateTime.parse(_selectedDate).toString().split(' ')[0],
                              style: AppTextStyles.subtitle,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.parse(_selectedDate),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            ).then((date) {
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date.toIso8601String().split('T')[0];
                                });
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status Filter
                Row(
                  children: [
                    Text('Filter by Status: ', style: AppTextStyles.caption),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: ['All', 'Scheduled', 'In Progress', 'Completed', 'Delayed']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text(
                          '${_filteredRoutes.length}',
                          style: AppTextStyles.headline.copyWith(color: AppColors.primary),
                        ),
                        Text('Total Routes', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text(
                          '${_filteredRoutes.where((r) => r['status'] == 'Completed').length}',
                          style: AppTextStyles.headline.copyWith(color: Colors.green),
                        ),
                        Text('Completed', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text(
                          '${_filteredRoutes.where((r) => r['status'] == 'In Progress').length}',
                          style: AppTextStyles.headline.copyWith(color: Colors.orange),
                        ),
                        Text('In Progress', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Routes List
          Expanded(
            child: _filteredRoutes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No routes for this date', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final route = _filteredRoutes[index];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: const Icon(Icons.route, color: Colors.white),
                              ),
                              title: Text(route['name'], style: AppTextStyles.subtitle),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimated: ${route['estimatedDuration']}'),
                                  if (route['actualDuration'] != null)
                                    Text('Actual: ${route['actualDuration']}'),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(route['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  route['status'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            
                            // Progress Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Progress', style: AppTextStyles.caption),
                                      Text(
                                        '${route['completedPools']}/${route['totalPools']} pools',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: route['totalPools'] > 0 
                                        ? route['completedPools'] / route['totalPools'] 
                                        : 0,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getStatusColor(route['status']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Pools Preview
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pools in this route:', style: AppTextStyles.caption),
                                  const SizedBox(height: 8),
                                  ...route['pools'].take(2).map<Widget>((pool) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.pool,
                                          size: 16,
                                          color: _getPoolStatusColor(pool['status']),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            pool['name'],
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getPoolStatusColor(pool['status']),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            pool['status'],
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  if (route['pools'].length > 2)
                                    Text(
                                      '... and ${route['pools'].length - 2} more',
                                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: 'View Details',
                                      onPressed: () => _viewRouteDetails(route),
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (route['status'] == 'Scheduled')
                                    Expanded(
                                      child: AppButton(
                                        label: 'Start Route',
                                        onPressed: () => _startRoute(route),
                                        color: Colors.green,
                                      ),
                                    ),
                                  if (route['status'] == 'In Progress')
                                    Expanded(
                                      child: AppButton(
                                        label: 'Complete',
                                        onPressed: () => _completeRoute(route),
                                        color: Colors.green,
                                      ),
                                    ),
                                ],
                              ),
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
  }
} 