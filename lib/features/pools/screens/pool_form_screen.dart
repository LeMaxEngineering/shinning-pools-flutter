import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class PoolFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pool;
  
  const PoolFormScreen({super.key, this.pool});

  @override
  State<PoolFormScreen> createState() => _PoolFormScreenState();
}

class _PoolFormScreenState extends State<PoolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _customerController = TextEditingController();
  final _sizeController = TextEditingController();
  final _equipmentController = TextEditingController();
  
  String _selectedStatus = 'Active';
  String _selectedType = 'Chlorine';
  String _selectedWaterQuality = 'Good';

  bool get _isEditing => widget.pool != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.pool!['name'];
      _locationController.text = widget.pool!['location'];
      _customerController.text = widget.pool!['customer'];
      _sizeController.text = widget.pool!['size'];
      _equipmentController.text = widget.pool!['equipment'];
      _selectedStatus = widget.pool!['status'];
      _selectedType = widget.pool!['type'];
      _selectedWaterQuality = widget.pool!['waterQuality'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _customerController.dispose();
    _sizeController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _savePool() {
    if (_formKey.currentState!.validate()) {
      final poolData = {
        'name': _nameController.text,
        'location': _locationController.text,
        'customer': _customerController.text,
        'status': _selectedStatus,
        'type': _selectedType,
        'size': _sizeController.text,
        'equipment': _equipmentController.text,
        'waterQuality': _selectedWaterQuality,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Pool updated successfully!' : 'Pool added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(poolData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pool' : 'Add New Pool'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Pool'),
                      content: const Text('Are you sure you want to delete this pool?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop({'action': 'delete'});
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Pool Information' : 'Add New Pool',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 24),

              // Pool Photo Section
              AppCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.pool, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Upload Pool Photo',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload coming soon!')),
                        );
                      },
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Basic Information
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Information', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _nameController,
                      label: 'Pool Name',
                      hint: 'Enter pool name (e.g., Main Pool - Hotel Marina)',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a pool name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'Enter pool location/address',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _customerController,
                      label: 'Customer',
                      hint: 'Enter customer name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a customer';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _sizeController,
                      label: 'Pool Size',
                      hint: 'Enter pool dimensions (e.g., 25m x 15m)',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pool size';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pool Specifications
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pool Specifications', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Active', 'Maintenance', 'Inactive']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Pool Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Chlorine', 'Salt Water', 'UV', 'Ozone', 'Bromine']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedWaterQuality,
                      decoration: const InputDecoration(
                        labelText: 'Water Quality',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Excellent', 'Good', 'Fair', 'Poor']
                          .map((quality) => DropdownMenuItem(
                                value: quality,
                                child: Text(quality),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWaterQuality = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Equipment Information
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipment Information', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _equipmentController,
                      label: 'Equipment',
                      hint: 'Enter equipment list (e.g., Filter, Pump, Heater)',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter equipment information';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Last Maintenance',
                        border: OutlineInputBorder(),
                        hintText: 'Auto-generated',
                      ),
                      enabled: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Next Maintenance',
                        border: OutlineInputBorder(),
                        hintText: 'To be scheduled',
                      ),
                      enabled: false,
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
                      label: _isEditing ? 'Update' : 'Save',
                      onPressed: _savePool,
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