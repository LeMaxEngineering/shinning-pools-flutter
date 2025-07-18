import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route.dart';
import '../../../core/services/auth_service.dart';
import '../../pools/services/pool_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../../../shared/ui/widgets/app_background.dart';

class RouteCreationScreen extends StatefulWidget {
  const RouteCreationScreen({super.key});

  @override
  State<RouteCreationScreen> createState() => _RouteCreationScreenState();
}

class _RouteCreationScreenState extends State<RouteCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _routeNotesController = TextEditingController();
  final List<Map<String, dynamic>> _selectedPools = [];
  List<Map<String, dynamic>> _companyPools = [];
  
  bool _isLoading = false;
  String? _error;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _routeNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null || user.companyId == null) {
      setState(() {
        _error = 'User not authenticated or associated with a company';
      });
      return;
    }
    
    setState(() {
      _companyId = user.companyId;
      _error = null;
    });

    final poolService = Provider.of<PoolService>(context, listen: false);
    final pools = await poolService.getCompanyPools(user.companyId!);
    setState(() {
      _companyPools = pools;
    });
  }

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pool')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

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
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePoolSelection(Map<String, dynamic> pool) {
    setState(() {
      if (_selectedPools.any((p) => p['id'] == pool['id'])) {
        _selectedPools.removeWhere((p) => p['id'] == pool['id']);
      } else {
        _selectedPools.add(pool);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create New Route'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                
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
                
                const SizedBox(height: 24),
                
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route Information',
                        style: AppTextStyles.headline,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _routeNameController,
                        label: 'Route Name',
                        hint: 'e.g., Monday Route',
                        validator: (value) => value == null || value.isEmpty 
                            ? 'Please enter a route name' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _routeNotesController,
                        label: 'Notes',
                        hint: 'Optional notes for the route',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pool Selection',
                        style: AppTextStyles.headline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select pools to include in this route:',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 12),
                      
                      if (_companyPools.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pool,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No pools available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _companyPools.length,
                          itemBuilder: (context, index) {
                            final pool = _companyPools[index];
                            final isSelected = _selectedPools.any((p) => p['id'] == pool['id']);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) => _togglePoolSelection(pool),
                                title: Text(pool['name'] ?? 'Unnamed Pool'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (pool['address'] != null)
                                      Text(pool['address']),
                                    if (pool['customer'] != null)
                                      Text(
                                        'Customer: ${pool['customer']}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                activeColor: AppColors.primary,
                                checkColor: Colors.white,
                              ),
                            );
                          },
                        ),
                      
                      if (_selectedPools.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedPools.length} pool(s) selected',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : AppButton(
                          label: 'Create Route',
                          onPressed: _createRoute,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 