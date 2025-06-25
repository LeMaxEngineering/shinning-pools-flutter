import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../models/customer.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  
  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedType = 'Standard';
  String _selectedStatus = 'Active';

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.customer!.name;
      _emailController.text = widget.customer!.email;
      _phoneController.text = widget.customer!.phone;
      _addressController.text = widget.customer!.address;
      _selectedType = widget.customer!.serviceTypeDisplay;
      _selectedStatus = widget.customer!.statusDisplay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically save to your database
      final customerData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'type': _selectedType,
        'status': _selectedStatus,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Customer updated successfully!' : 'Customer added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(customerData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add New Customer'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Customer'),
                      content: const Text('Are you sure you want to delete this customer?'),
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
                _isEditing ? 'Edit Customer Information' : 'Add New Customer',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 24),

              // Company Logo Section
              AppCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.business, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Upload Logo',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logo upload coming soon!')),
                        );
                      },
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Company Information
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Company Information', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                      sanitizationType: 'text',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      sanitizationType: 'email',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Phone',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                      sanitizationType: 'phone',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Address',
                      controller: _addressController,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                      sanitizationType: 'address',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Service Information
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service Information', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Standard', 'Premium']
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
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Active', 'Inactive']
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
                    
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Number of Pools',
                        border: OutlineInputBorder(),
                        hintText: '0',
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
                      onPressed: _saveCustomer,
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