import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pool;
  final String? poolId;

  const MaintenanceFormScreen({
    Key? key,
    this.pool,
    this.poolId,
  }) : super(key: key);

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _chemicalsController = TextEditingController();
  final _equipmentController = TextEditingController();
  
  String _selectedMaintenanceType = 'Regular';
  String _selectedStatus = 'Completed';
  DateTime _maintenanceDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pool != null) {
      // Pre-fill with pool information if available
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _chemicalsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _maintenanceDate) {
      setState(() {
        _maintenanceDate = picked;
      });
    }
  }

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement maintenance service call
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance record saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving maintenance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.pool != null 
              ? 'Add Maintenance - ${widget.pool!['name']}'
              : 'Add Maintenance',
        ),
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
              // Pool Information (if available)
              if (widget.pool != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pool Information', style: AppTextStyles.headline2),
                      const SizedBox(height: 16),
                      Text('Name: ${widget.pool!['name'] ?? 'N/A'}'),
                      Text('Address: ${widget.pool!['address'] ?? 'N/A'}'),
                      Text('Status: ${widget.pool!['status'] ?? 'N/A'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Maintenance Details
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maintenance Details', style: AppTextStyles.headline2),
                    const SizedBox(height: 16),
                    
                    // Maintenance Type
                    DropdownButtonFormField<String>(
                      value: _selectedMaintenanceType,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Regular',
                        'Chemical Treatment',
                        'Equipment Repair',
                        'Filter Cleaning',
                        'Water Quality Test',
                        'Emergency',
                      ].map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMaintenanceType = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a maintenance type';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Maintenance Date
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Maintenance Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_maintenanceDate.day}/${_maintenanceDate.month}/${_maintenanceDate.year}',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Completed',
                        'In Progress',
                        'Scheduled',
                        'Cancelled',
                      ].map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chemicals Used
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chemicals Used', style: AppTextStyles.headline2),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _chemicalsController,
                      label: 'Chemicals & Quantities',
                      hint: 'e.g., Chlorine 2kg, pH+ 500ml, Algaecide 1L',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Equipment Work
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipment Work', style: AppTextStyles.headline2),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _equipmentController,
                      label: 'Equipment Maintenance',
                      hint: 'e.g., Filter cleaned, Pump checked, Heater serviced',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notes
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Observations', style: AppTextStyles.headline2),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _notesController,
                      label: 'Additional Notes',
                      hint: 'Enter any additional observations or notes...',
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: 'Save Maintenance',
                      onPressed: _isLoading ? null : _saveMaintenance,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 