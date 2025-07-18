import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../models/customer.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../../core/services/auth_service.dart';

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
  
  // Photo upload related
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  UploadTask? _currentUploadTask;
  bool _isUploading = false;
  bool _photoRemoved = false;

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
      // Handle existing customer photo if available
      _uploadedImageUrl = widget.customer!.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentUploadTask?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 40,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        print('Selected customer image size: ${bytes.length} bytes');
        
        setState(() {
          _selectedImageBytes = bytes;
          _photoRemoved = false; // Reset removed flag when new image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImageBytes == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      // Handle CORS issues in development mode
      if (kDebugMode && kIsWeb) {
        print('Development mode: Using data URL for customer photo...');
        
        // Create data URL for development mode
        final base64String = base64Encode(_selectedImageBytes!);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        
        // Check size limit
        if (dataUrl.length > 900000) {
          print('Customer photo too large (${dataUrl.length} bytes), skipping...');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo too large for development mode - customer saved without photo'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return null;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using development photo preview'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        return dataUrl;
      }

      // Production upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageRef = storageRef.child('customers/customer_$timestamp.jpg');
      
      final uploadTask = imageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      _currentUploadTask = uploadTask;
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Customer photo upload timeout');
          _currentUploadTask?.cancel();
          _currentUploadTask = null;
          throw TimeoutException('Upload timeout', const Duration(seconds: 30));
        },
      );
      
      _currentUploadTask = null;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await imageRef.getDownloadURL();
        print('Customer image uploaded successfully: $downloadUrl');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return downloadUrl;
      }
      
    } catch (e) {
      print('Customer photo upload failed: $e');
      _currentUploadTask = null;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed - customer will be saved without photo'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
    
    return null;
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (_uploadedImageUrl != null && !_photoRemoved) {
      // Handle both network URLs and data URLs
      if (_uploadedImageUrl!.startsWith('data:image/')) {
        try {
          final base64Data = _uploadedImageUrl!.split(',')[1];
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        } catch (e) {
          print('Error decoding customer photo data URL: $e');
          return null;
        }
      } else {
        return NetworkImage(_uploadedImageUrl!);
      }
    }
    return null;
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        final customerViewModel = Provider.of<CustomerViewModel>(context, listen: false);
        
        // Upload photo if selected
        String? photoUrl;
        if (_selectedImageBytes != null) {
          photoUrl = await _uploadImageToFirebase();
        }

        bool success;
        if (_isEditing) {
          // Update existing customer
          final updateData = <String, dynamic>{
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'serviceType': _selectedType.toLowerCase(),
            'status': _selectedStatus.toLowerCase(),
          };

          // Handle email updates - only add if not empty
          if (_emailController.text.trim().isNotEmpty) {
            updateData['email'] = _emailController.text.trim();
          }

          // Handle photo updates carefully
          if (photoUrl != null) {
            // New photo was uploaded
            updateData['photoUrl'] = photoUrl;
          } else if (_photoRemoved) {
            // User explicitly removed the photo
            updateData['photoUrl'] = null;
          }
          // If no new photo and not removed, don't modify photoUrl field

          success = await customerViewModel.updateCustomer(widget.customer!.id, updateData);
        } else {
          // Create new customer
          success = await customerViewModel.createCustomer(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            serviceType: _selectedType.toLowerCase(),
            status: _selectedStatus.toLowerCase(),
            photoUrl: photoUrl,
          );
        }

        if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
              content: Text(
                _isEditing 
                  ? 'Customer updated successfully!' 
                  : 'Customer added successfully! Phone: ${_phoneController.text.trim()}',
              ),
          backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
        ),
      );

          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          // Handle error from CustomerViewModel
          final error = customerViewModel.error.isEmpty ? 'Unknown error occurred' : customerViewModel.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save customer: $error'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    if (authService.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create New Route')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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

              // Customer Photo Section
              AppCard(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                          backgroundImage: _getImageProvider(),
                          child: _getImageProvider() == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    AppButton(
                          label: _selectedImageBytes != null ? 'Change Photo' : 'Upload Photo',
                          onPressed: _isUploading ? null : _pickImage,
                          color: AppColors.secondary,
                        ),
                        if (_selectedImageBytes != null || (_uploadedImageUrl != null && !_photoRemoved)) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _isUploading ? null : () {
                              setState(() {
                                _selectedImageBytes = null;
                                // In edit mode, mark for removal but keep original reference
                                if (_isEditing) {
                                  // Keep _uploadedImageUrl to show we're removing existing photo
                                  _photoRemoved = true;
                                } else {
                                  // In create mode, clear everything
                                  _uploadedImageUrl = null;
                                }
                              });
                      },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove Photo',
                          ),
                        ],
                      ],
                    ),
                    if (_selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Photo selected (${(_selectedImageBytes!.length / 1024).round()} KB)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Customer Information
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Information', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phone number is required for customer identification. Email is optional.',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      hint: 'Optional - for notifications and communication',
                      validator: (value) {
                        // Email is optional, but if provided, must be valid
                        if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email format';
                          }
                        }
                        return null;
                      },
                      sanitizationType: 'email',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Phone *',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      hint: 'Required - primary contact method',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        // Basic phone validation - you can make this more specific
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                      sanitizationType: 'phone',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AppTextField.addressField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter customer address',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                      maxLines: 3,
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
                      dropdownColor: AppColors.primary,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primary,
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
                      dropdownColor: AppColors.primary,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primary,
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
                      label: _isUploading 
                        ? 'Processing...' 
                        : (_isEditing ? 'Update' : 'Save'),
                      onPressed: _isUploading ? null : _saveCustomer,
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