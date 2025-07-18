import 'package:flutter/material.dart';
import 'routes_list_screen.dart';
import 'assignments_list_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/route_viewmodel.dart';
import '../viewmodels/assignment_viewmodel.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../../../shared/ui/widgets/app_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pools/services/pool_service.dart';
import '../models/route.dart';
import '../screens/assignments_history_screen.dart';


class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({Key? key}) : super(key: key);

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _assignmentFormKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedWorkerId;
  String? _selectedWorkerName;
  bool _isLoading = false;
  String? _error;
  String? _companyId;
  bool _isAdmin = false;

  List<Map<String, dynamic>> _availableRoutes = [];
  Map<String, dynamic>? _selectedRoute;
  List<Map<String, dynamic>> _availableAssignees = [];

  // Route Creation state
  final _routeFormKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _routeNotesController = TextEditingController();
  final List<Map<String, dynamic>> _selectedPools = [];
  List<Map<String, dynamic>> _companyPools = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndLoadData();
    });
  }

  Future<void> _checkPermissionsAndLoadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null || (!user.isAdmin && !user.isRoot)) {
      // If user is not an admin or root, show an error and navigate back.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied. You do not have permission to view this page.'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate back to the previous screen (dashboard)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }
    // If permissions are sufficient, load the initial data for the screen.
    _loadInitialData(context);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _routeNameController.dispose();
    _routeNotesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null || user.companyId == null) {
      setState(() { _error = 'User not authenticated or associated with a company'; });
      return;
    }
    setState(() {
      _companyId = user.companyId;
      _isAdmin = user.isAdmin || user.isRoot;
      _error = null;
    });

    final poolService = Provider.of<PoolService>(context, listen: false);
    final pools = await poolService.getCompanyPools(user.companyId!);
    setState(() {
      _companyPools = pools;
    });
    
    final firestore = FirebaseFirestore.instance;
    final routesSnapshot = await firestore.collection('routes')
      .where('companyId', isEqualTo: user.companyId)
        .where('status', isNotEqualTo: 'template') // Don't show templates in assignment dropdown
      .get();
    
    setState(() {
      _availableRoutes = routesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
        'id': doc.id,
          'routeName': data['routeName'] ?? 'Unnamed Route',
          'status': data['status'] ?? 'created',
          'date': data['date'],
          'stops': data['stops'] ?? [],
          ...data,
        };
      }).toList();
      
      if (_availableRoutes.isNotEmpty) {
        _selectedRoute = _availableRoutes.first;
      }
    });

    final usersSnapshot = await firestore.collection('users')
      .where('companyId', isEqualTo: user.companyId)
      .where('role', whereIn: ['worker', 'admin'])
      .get();
    setState(() {
      _availableAssignees = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
        'id': doc.id,
          'name': data['displayName'] ?? data['email']?.split('@').first ?? 'Unknown User',
          ...data,
        };
      }).toList();
    });
  }

  Future<void> _assignRoute(BuildContext context) async {
    if (_selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker')),
      );
      return;
    }
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a route')),
      );
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    try {
      final assignmentViewModel = Provider.of<AssignmentViewModel>(context, listen: false);
      DateTime? routeDate;
      if (_selectedRoute != null && _selectedRoute!['date'] != null) {
      final rawRouteDate = _selectedRoute!['date'];
      if (rawRouteDate is Timestamp) {
        routeDate = rawRouteDate.toDate();
      } else if (rawRouteDate is DateTime) {
        routeDate = rawRouteDate;
        }
      }
      
      final success = await assignmentViewModel.createAssignment(
        routeId: _selectedRoute!['id'],
        workerId: _selectedWorkerId!,
        notes: _notesController.text.trim(),
        companyId: _companyId!,
        routeName: _selectedRoute!['routeName'],
        workerName: _selectedWorkerName,
        routeDate: routeDate ?? _selectedDate,
      );

      if (context.mounted) {
      if (success) {
        setState(() {
          _selectedWorkerId = null;
          _selectedWorkerName = null;
          _notesController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create assignment: ${assignmentViewModel.error}'),
            backgroundColor: Colors.red,
          ),
        );
        }
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _createRoute() async {
    if (!_routeFormKey.currentState!.validate()) return;
    if (_selectedPools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pool')),
      );
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final newRoute = RouteModel(
        id: '', // Firestore will generate
        companyId: _companyId!,
        routeName: _routeNameController.text.trim(),
        stops: _selectedPools.map((p) => p['id'] as String).toList(),
        status: 'ACTIVE',
        notes: _routeNotesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('routes').add(newRoute.toFirestore());

      if (context.mounted) {
        setState(() {
          _routeNameController.clear();
          _routeNotesController.clear();
          _selectedPools.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _tabController.animateTo(0); // Switch to routes list
        _loadInitialData(context); // Refresh routes list
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null || (!user.isAdmin && !user.isRoot)) {
      // Fallback for non-admin users or other roles
    return Scaffold(
        appBar: AppBar(
          title: const Text('Route Management'),
        ),
        body: const Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }

    return DefaultTabController(
      length: user.role.isAdmin ? 3 : 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Route Management'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              const Tab(text: 'Routes'),
              const Tab(text: 'Assignments'),
              if (user.role.isAdmin) const Tab(text: 'History'),
            ],
          ),
        ),
        body: AppBackground(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoutesTab(),
              _buildAssignmentTab(),
              if (user.role.isAdmin) const AssignmentsHistoryScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
                    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
          if (_isAdmin) _buildRouteCreationForm(),
          if (_isAdmin) const SizedBox(height: 24),
          const Text('Current Routes', style: AppTextStyles.headline),
          const SizedBox(height: 16),
          const RoutesListScreen(),
        ],
      ),
    );
  }

  Widget _buildRouteCreationForm() {
    return Column(
      children: [
        // Route Creation Title Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade500,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Creation',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define the route name and select pools for this route',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
      child: Form(
        key: _routeFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
              const Text('Route Information', style: AppTextStyles.headline),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _routeNameController,
                                      label: 'Route Name',
                hint: 'e.g., Monday Route',
                validator: (value) => value == null || value.isEmpty ? 'Please enter a route name' : null,
                              ),
                              const SizedBox(height: 16),
              AppTextField(
                controller: _routeNotesController,
                label: 'Notes',
                hint: 'Optional notes for the route',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text('Pool Selection', style: AppTextStyles.headline),
                                        const SizedBox(height: 16),
              _buildPoolSelector(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                AppButton(
                  label: 'Create Route',
                  onPressed: _createRoute,
                                                      ),
                                                    ],
                                                  ),
                                                ),
        ),
      ],
    );
  }

  Widget _buildPoolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField(
          decoration: InputDecoration(
            labelText: 'Selected Pools (${_selectedPools.length})',
            border: const OutlineInputBorder(),
          ),
          items: const [],
          onChanged: null, // No action, just for display
          // Instead of items, we'll build the selector dialog on tap
        ),
                                          const SizedBox(height: 8),
        InkWell(
          onTap: _selectPools,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                Icon(Icons.add, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Add/Remove Pools', style: TextStyle(color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
        const SizedBox(height: 16),
        const Text('Selected Pools:', style: AppTextStyles.subtitle),
                              const SizedBox(height: 8),
        if (_selectedPools.isEmpty)
          const Text('No pools selected.')
        else
          ..._selectedPools.map((pool) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(pool['name'] ?? 'Unnamed Pool'),
            subtitle: Text(pool['address'] ?? 'No address'),
          )),
      ],
    );
  }


  void _selectPools() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allSelected = _companyPools.isNotEmpty && _selectedPools.length == _companyPools.length;
            return AlertDialog(
              title: const Text('Select Pools'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: _companyPools.isEmpty
                    ? const Center(child: Text('No pools available.'))
                    : Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('Select All Pools'),
                            value: allSelected,
                            onChanged: (bool? selected) {
                              setDialogState(() {
                                setState(() {
                                  if (selected == true) {
                                    _selectedPools.clear();
                                    _selectedPools.addAll(_companyPools);
                                  } else {
                                    _selectedPools.clear();
                                  }
                                });
                              });
                            },
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView(
                        children: _companyPools.map((pool) {
                          final isSelected = _selectedPools.any((p) => p['id'] == pool['id']);
                          return CheckboxListTile(
                            title: Text(pool['name'] ?? 'Unnamed Pool'),
                            subtitle: Text(pool['address'] ?? 'No Address'),
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setDialogState(() {
                                setState(() {
                                  if (selected == true) {
                                    _selectedPools.add(pool);
                                  } else {
                                    _selectedPools.removeWhere((p) => p['id'] == pool['id']);
                                  }
                                });
                              });
                            },
                          );
                        }).toList(),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildAssignmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Orange card for the title, matching the Routes tab style
          AppCard(
            backgroundColor: AppColors.warning, // Use orange color
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_road_outlined, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                        'Assign Route',
                        style: AppTextStyles.headline.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a route and assign it to a worker',
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The list of assignments (which includes the form)
          const AssignmentsListScreen(),
        ],
      ),
    );
  }
} 