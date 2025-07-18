import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../viewmodels/route_viewmodel.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_map_screen.dart';
import 'route_maintenance_map_screen.dart';

class RoutesListScreen extends StatefulWidget {
  final bool showHistorical;
  const RoutesListScreen({Key? key, this.showHistorical = false}) : super(key: key);

  @override
  _RoutesListScreenState createState() => _RoutesListScreenState();
}

class _RoutesListScreenState extends State<RoutesListScreen> {
  Future<String> _getPoolAddress(String poolId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pools').doc(poolId).get();
      if (doc.exists && doc.data()!.containsKey('address')) {
        return doc.data()!['address'] as String;
      }
      return 'Address not found';
    } catch (e) {
      return 'Error fetching address';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    if (user == null || user.companyId == null) {
      return const Center(child: Text('User not authenticated or not associated with a company.'));
    }
    final cardColors = [
      AppColors.primary,
      AppColors.success,
      Colors.orange,
      Colors.deepPurple,
    ];
    return Consumer<RouteViewModel>(
      builder: (context, routeViewModel, _) {
        return StreamBuilder<List<Map<String, dynamic>>>(
                stream: routeViewModel.streamCompanyRoutes(user.companyId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final routes = snapshot.data ?? [];
                  final filteredRoutes = routes.where((route) {
                    final status = (route['status'] as String? ?? 'active').toLowerCase();
                    final isHistorical = status == 'completed' || status == 'cancelled';

                    if (widget.showHistorical) {
                      if (!isHistorical) return false;
                    } else {
                      if (isHistorical) return false;
                    }

                    final matchesStatus = routeViewModel.statusFilter == 'All' ||
                                         (route['status'] ?? 'ACTIVE') == routeViewModel.statusFilter.toLowerCase().replaceAll(' ', '_');
                    final matchesWorker = routeViewModel.workerFilter == 'All' ||
                                         (route['worker'] ?? '') == routeViewModel.workerFilter;
                    return matchesStatus && matchesWorker;
                  }).toList();
                  
                  // Sort routes by name in ascending order
                  filteredRoutes.sort((a, b) {
                    final nameA = (a['routeName'] ?? '').toString().toLowerCase();
                    final nameB = (b['routeName'] ?? '').toString().toLowerCase();
                    return nameA.compareTo(nameB);
                  });
                  if (filteredRoutes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.route, size: 80, color: AppColors.primary),
                            SizedBox(height: 20),
                            Text(
                              'No Routes Found',
                              style: AppTextStyles.headline,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tap the "+" button below to create your first route.',
                              style: AppTextStyles.subtitle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRoutes.length,
              itemBuilder: (context, index) {
                      final route = filteredRoutes[index];
                      return AppCard(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        backgroundColor: cardColors[index % cardColors.length],
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Image.asset(
                                'assets/img/map_icon.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RouteMaintenanceMapScreen(routeId: route['id']),
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                title: Text(
                                  route['routeName'] ?? 'Unnamed Route',
                                  style: AppTextStyles.subtitle.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Created: ' +
                                    (route['createdAt'] != null && route['createdAt'] is Timestamp
                                      ? DateFormat('MMMM dd/yyyy').format(route['createdAt'].toDate())
                                      : 'N/A') +
                                  '\nStatus: ' +
                                    (route['status'] ?? 'N/A').toString(),
                                  style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                children: (route['stops'] as List<dynamic>).map<Widget>((stop) {
                                  final poolId = stop as String?;
                                  if (poolId == null) {
                                    return const ListTile(title: Text('Invalid stop data', style: TextStyle(color: Colors.white)));
                                  }
                                  return FutureBuilder<String>(
                                    future: _getPoolAddress(poolId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const ListTile(title: Text('Loading address...', style: TextStyle(color: Colors.white70)));
                                      }
                                      if (snapshot.hasError) {
                                        return ListTile(title: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                                      }
                                      return ListTile(
                                        leading: const Icon(Icons.location_on, color: Colors.white, size: 16),
                                        title: Text(snapshot.data ?? 'No address', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        dense: true,
                                      );
                                    },
                                  );
                                }).toList(),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                      tooltip: 'Edit',
                                      onPressed: () async {
                                        final TextEditingController nameController = TextEditingController(text: route['routeName'] ?? '');
                                        DateTime selectedDate = (route['date'] != null && route['date'] is Timestamp) ? route['date'].toDate() : DateTime.now();
                                        String status = (route['status'] ?? 'ACTIVE').toString();
                                        final statuses = ['ACTIVE', 'INACTIVE'];
                                        // Ensure the current status is in the available options
                                        if (!statuses.contains(status)) {
                                          status = 'ACTIVE'; // Default to 'ACTIVE' if status is not in the list
                                        }
                                        final formKey = GlobalKey<FormState>();
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Edit Route'),
                                            content: Form(
                                              key: formKey,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextFormField(
                                                      controller: nameController,
                                                      decoration: const InputDecoration(labelText: 'Route Name'),
                                                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Row(
                                                      children: [
                                                        const Text('Date: '),
                                                        TextButton(
                                                          child: Text(DateFormat('MMMM dd/yyyy').format(selectedDate)),
                                                          onPressed: () async {
                                                            final picked = await showDatePicker(
                                                              context: context,
                                                              initialDate: selectedDate,
                                                              firstDate: DateTime(2020),
                                                              lastDate: DateTime(2100),
                                                            );
                                                            if (picked != null) {
                                                              selectedDate = picked;
                                                              (context as Element).markNeedsBuild();
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    DropdownButtonFormField<String>(
                                                      value: status,
                                                      decoration: const InputDecoration(labelText: 'Status'),
                                                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                                      onChanged: (v) { if (v != null) status = v; },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  if (formKey.currentState?.validate() != true) return;
                                                  final routeViewModel = Provider.of<RouteViewModel>(context, listen: false);
                                                  final routeId = route['id'];
                                                  if (routeId != null) {
                                                    final data = {
                                                      'routeName': nameController.text.trim(),
                                                      'date': Timestamp.fromDate(selectedDate),
                                                      'status': status,
                                                    };
                                                    final success = await routeViewModel.updateRoute(routeId, data);
                                                    Future.microtask(() {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(success ? 'Route updated.' : 'Failed to update route.'),
                                                            backgroundColor: success ? Colors.green : Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    });
                                                    if (success && context.mounted) Navigator.of(context).pop();
                                                  }
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Route'),
                                            content: const Text('Are you sure you want to delete this route?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final routeViewModel = Provider.of<RouteViewModel>(context, listen: false);
                                          final routeId = route['id'];
                                          if (routeId != null) {
                                            final success = await routeViewModel.deleteRoute(routeId);
                                            Future.microtask(() {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(success ? 'Route deleted.' : 'Failed to delete route.'),
                                                    backgroundColor: success ? Colors.green : Colors.red,
                                                  ),
                                                );
                                              }
                                            });
                                          }
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
              },
            );
          },
        );
      },
    );
  }
} 