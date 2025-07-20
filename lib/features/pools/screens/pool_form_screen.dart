import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import 'package:provider/provider.dart';
import '../../customers/viewmodels/customer_viewmodel.dart';
import '../services/pool_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import '../../../shared/ui/widgets/app_background.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/models/geocoding_result.dart';

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
  final _monthlyCostController = TextEditingController();
  
  String _selectedStatus = 'active';
  String _selectedType = 'Chlorine';
  String _selectedWaterQuality = 'good';
  String? _selectedCustomerEmail;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  bool _isLoading = false;
  
  // Photo upload related
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  UploadTask? _currentUploadTask;

  final GeocodingService _geocodingService = GeocodingService();

  final List<String> _statusOptions = ['active', 'maintenance', 'inactive'];
  final List<String> _typeOptions = ['Chlorine', 'Salt Water', 'UV', 'Ozone', 'Bromine'];
  final List<String> _waterQualityOptions = ['excellent', 'good', 'fair', 'poor'];

  bool get _isEditing => widget.pool != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize customer data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final customerViewModel = Provider.of<CustomerViewModel>(context, listen: false);
        customerViewModel.initialize();
      } catch (e) {
      }
    });
    
    if (_isEditing) {
      _nameController.text = widget.pool!['name'] ?? '';
      _locationController.text = widget.pool!['address'] ?? widget.pool!['location'] ?? '';
      _sizeController.text = widget.pool!['size']?.toString() ?? '';
      
      // Handle equipment properly - it can be in specifications or at root level
      List<dynamic> equipment = [];
      
      // Check multiple possible locations for equipment data
      if (widget.pool!['specifications'] != null && widget.pool!['specifications']['equipment'] != null) {
        equipment = widget.pool!['specifications']['equipment'] as List<dynamic>;
      } else if (widget.pool!['equipment'] != null) {
        equipment = widget.pool!['equipment'] as List<dynamic>;
      }
      
      // Handle both string and list formats
      String equipmentText = '';
      if (equipment.isNotEmpty) {
        if (equipment.first is String) {
          // It's already a list of strings
          equipmentText = equipment.join(', ');
        } else {
          // Convert to strings if needed
          equipmentText = equipment.map((e) => e.toString()).join(', ');
        }
      }
      
      _equipmentController.text = equipmentText;
      
      _monthlyCostController.text = widget.pool!['monthlyCost']?.toString() ?? '0.0';
      _selectedStatus = widget.pool!['status'] ?? 'active';
      _selectedType = widget.pool!['specifications']?['type'] ?? widget.pool!['type'] ?? 'Chlorine';
      _selectedWaterQuality = widget.pool!['waterQualityMetrics']?['quality'] ?? widget.pool!['waterQuality'] ?? 'good';
      _selectedCustomerEmail = widget.pool!['customerEmail'];
      _selectedCustomerId = widget.pool!['customerId'];
      _selectedCustomerName = widget.pool!['customerName'];
      _uploadedImageUrl = widget.pool!['photoUrl'];
      
      // Set the customer controller text with the initial value
      _customerController.text = _selectedCustomerName ?? '';
      
      // If customer name is missing but we have customer ID and email, we'll load it after customers are available
      if (_selectedCustomerName == null && _selectedCustomerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadMissingCustomerName();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Check if we're on web platform and show a warning about CORS
    if (kIsWeb) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Image Upload Notice'),
            content: const Text(
              'Image upload on web may be blocked by browser security settings. '
              'If upload fails, the pool will be saved without the photo. '
              'Continue with image selection?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      
      if (shouldContinue != true) {
        return;
      }
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,  // Smaller size to reduce file size
        maxHeight: 600,
        imageQuality: 40, // Lower quality for smaller files
      );
      
      if (image != null) {
        // Always convert to bytes for consistent handling across platforms
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImageBytes = bytes;
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

    // Handle CORS issues in development mode
    if (kDebugMode && kIsWeb) {
      print('Development mode: Using data URL for pool photo...');
      
      // Create data URL for development mode
      final base64String = base64Encode(_selectedImageBytes!);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      // Check size limit (data URLs have overhead)
      if (dataUrl.length > 900000) {
        print('Pool photo too large (${dataUrl.length} bytes), skipping...');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo too large for development mode - pool saved without photo'),
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

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageRef = storageRef.child('pools/pool_$timestamp.jpg');
      
      // Upload with normal timeout for production
      final uploadTask = imageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      _currentUploadTask = uploadTask;
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Upload timeout after 30 seconds');
          _currentUploadTask?.cancel();
          _currentUploadTask = null;
          throw TimeoutException('Upload timeout', const Duration(seconds: 30));
        },
      );
      
      _currentUploadTask = null;
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await imageRef.getDownloadURL();
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload failed - pool will be saved without photo'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: ${e.message}');
      _currentUploadTask = null; // Clear reference
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload timed out - pool will be saved without photo changes'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null;
    } on FirebaseException catch (e) {
      print('Firebase upload error: ${e.code} - ${e.message}');
      _currentUploadTask = null; // Clear reference
      if (mounted) {
        // For CORS or permission errors, continue without photo
        if (e.code.contains('cors') || e.code.contains('unauthorized') || e.code.contains('storage')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload not available - pool data will be saved'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return null; // Continue without photo
        }
        
        // For other Firebase errors, show appropriate message and continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: ${e.message}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null; // Continue without photo
    } catch (e) {
      print('General upload error: $e');
      _currentUploadTask = null; // Clear reference
      if (mounted) {
        // Check if error message contains CORS-related keywords
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('cors') || 
            errorStr.contains('access control') ||
            errorStr.contains('xmlhttprequest') ||
            errorStr.contains('preflight') ||
            errorStr.contains('cross-origin') ||
            errorStr.contains('origin') ||
            errorStr.contains('blocked')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload blocked by browser security - pool data will be saved'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return null; // Continue without photo
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed - pool data will be saved'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return null; // Continue without photo
      }
      return null;
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing upload tasks
    _currentUploadTask?.cancel();
    _currentUploadTask = null;
    
    _nameController.dispose();
    _locationController.dispose();
    _customerController.dispose();
    _sizeController.dispose();
    _equipmentController.dispose();
    _monthlyCostController.dispose();
    super.dispose();
  }

  Future<Map<String, double?>> _geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
    } catch (e) {
      print('Geocoding failed: $e');
    }
    return {'latitude': null, 'longitude': null};
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _savePool();
    }
  }

  Future<void> _savePool() async {
      if (_selectedCustomerName == null || _selectedCustomerId == null) {
      _showError('Please select a customer.');
        return;
    }
    _verifyAddressAndSubmit();
  }

  Future<void> _verifyAddressAndSubmit() async {
    setState(() => _isLoading = true);

    final address = _locationController.text.trim();
    GeocodingResult? geocodeResult;

    try {
      geocodeResult = await _geocodingService.geocodeAddress(address);
    } catch (e) {
      print('Geocoding failed during form submission: $e');
      _showError('Could not verify address. Please try again.');
      setState(() => _isLoading = false);
      return;
    }

    if (geocodeResult == null) {
      _showError('Could not find a valid location for the address entered. Please check the address.');
      setState(() => _isLoading = false);
      return;
    }

    // If Google's formatted address is different, ask the user to confirm.
    if (geocodeResult.formattedAddress.toLowerCase() != address.toLowerCase()) {
      final bool? confirmed = await _showAddressConfirmationDialog(address, geocodeResult.formattedAddress);
      if (confirmed == true) {
        // User accepted the suggestion, proceed with the corrected address.
        _locationController.text = geocodeResult.formattedAddress;
        _savePoolData(geocodeResult);
      } else if (confirmed == false) {
        // User rejected the suggestion, proceed with their original address.
        _savePoolData(geocodeResult);
      }
      // If confirmed is null (dialog dismissed), do nothing and stop loading.
      if (confirmed == null) {
        setState(() => _isLoading = false);
      }
    } else {
      // Address is a perfect match, proceed with saving.
      _savePoolData(geocodeResult);
    }
  }

  Future<bool?> _showAddressConfirmationDialog(String originalAddress, String suggestedAddress) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Address'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('The address you entered is slightly different from the one found on the map.'),
                const SizedBox(height: 16),
                Text('You Entered:', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
                Text(originalAddress),
                const SizedBox(height: 10),
                Text('Suggested:', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text(suggestedAddress),
                const SizedBox(height: 16),
                const Text('Which address would you like to use?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Use My Address'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Use Suggested'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePoolData(GeocodingResult geocodeResult) async {
    // This function will now contain the original logic from _submitForm
    // It receives the verified geocoding result to save.
    String? finalPhotoUrl = _uploadedImageUrl;
        if (_selectedImageBytes != null) {
      final photoUrl = await _uploadImageToFirebase();
      if (photoUrl != null) {
        finalPhotoUrl = photoUrl;
      }
        } else if (_isEditing) {
          // Keep existing photo URL when editing
      finalPhotoUrl = _uploadedImageUrl;
    }

    final poolService = context.read<PoolService>();
    final currentUser = context.read<AuthService>().currentUser;

    if (currentUser?.companyId == null) {
      _showError('Error: No company ID found.');
      setState(() => _isLoading = false);
      return;
    }

    try {
        bool success;
        if (_isEditing) {
          // Update existing pool
          Map<String, dynamic> poolData = {
            'customerId': _selectedCustomerId!,
            'customerEmail': _selectedCustomerEmail,
            'customerName': _selectedCustomerName,
            'name': _nameController.text.trim(),
            'address': _locationController.text.trim(),
          'latitude': geocodeResult.coordinates.latitude,
          'longitude': geocodeResult.coordinates.longitude,
            'size': _parseSize(_sizeController.text.trim()),
            'specifications': {
              'type': _selectedType,
              'equipment': _equipmentController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            },
            'status': _selectedStatus.toLowerCase(),
            'monthlyCost': double.tryParse(_monthlyCostController.text.trim()) ?? 0.0,
            'waterQualityMetrics': {
              'quality': _selectedWaterQuality,
              'lastTested': FieldValue.serverTimestamp(),
            },
          };

          // Handle photo upload for updates
          if (_selectedImageBytes != null) {
            try {
              final photoUrl = await _uploadImageToFirebase();
              if (photoUrl != null) {
                poolData['photoUrl'] = photoUrl;
              }
            } catch (e) {
              print('Photo upload failed during pool update: $e');
              // Failed to process new image, keep existing
              print('Failed to process new image, keeping existing photo');
            }
          }
          // If no new image selected, keep existing photo URL (don't update photoUrl field)

          success = await poolService.updatePool(widget.pool!['id'], poolData);
        } else {
          // Create new pool
          success = await poolService.createPool(
            customerId: _selectedCustomerId!,
            name: _nameController.text.trim(),
            address: _locationController.text.trim(),
          latitude: geocodeResult.coordinates.latitude,
          longitude: geocodeResult.coordinates.longitude,
            size: _parseSize(_sizeController.text.trim()),
            specifications: {
              'type': _selectedType,
              'equipment': _equipmentController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            },
            status: _selectedStatus.toLowerCase(),
            companyId: currentUser!.companyId!,
            monthlyCost: double.tryParse(_monthlyCostController.text.trim()) ?? 0.0,
          photoUrl: finalPhotoUrl,
            customerEmail: _selectedCustomerEmail,
            customerName: _selectedCustomerName,
          );
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Pool updated successfully!' : 'Pool created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
        _showError('Failed to ${_isEditing ? 'update' : 'create'} pool: ${poolService.error ?? 'Unknown error'}');
        }
      } catch (e) {
      _showError('Error: ${e.toString()}');
      } finally {
        if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deletePool() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Pool'),
          content: const Text('Are you sure you want to delete this pool? This action cannot be undone.'),
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
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final poolService = context.read<PoolService>();
      
      try {
        final success = await poolService.deletePool(widget.pool!['id']);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pool deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          _showError('Failed to delete pool: ${poolService.error ?? 'Unknown error'}');
        }
      } catch (e) {
        _showError('Error: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerViewModel>(
      builder: (context, customerViewModel, child) {
        final customers = customerViewModel.customers;
        final customerNames = customers.map((c) => c.name).toList();
        
        // Ensure CustomerViewModel is initialized if customers are empty and not loading
        if (customers.isEmpty && !customerViewModel.isLoading && customerViewModel.error.isEmpty) {
          Future.microtask(() => customerViewModel.initialize());
        }
        
        // Fallback: If _selectedType is not in _typeOptions, set it to 'Chlorine'
        if (!_typeOptions.contains(_selectedType)) {
          _selectedType = 'Chlorine';
        }
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Pool' : 'Add New Pool'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deletePool,
                ),
            ],
          ),
          body: AppBackground(
            child: SingleChildScrollView(
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
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _getImageProvider(),
                            child: _hasSelectedImage()
                                ? null
                                : const Icon(Icons.pool, size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: _hasSelectedImage() || _uploadedImageUrl != null 
                                ? 'Change Pool Photo' 
                                : 'Upload Pool Photo',
                            onPressed: _pickImage,
                            color: AppColors.secondary,
                          ),
                          if (_hasSelectedImage()) ...[
                            const SizedBox(height: 8),
                            Text(
                              'New image selected',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
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
                          
                          AppTextField.addressField(
                            controller: _locationController,
                            label: 'Pool Address',
                            hint: 'Enter pool address (e.g., 123 Main St, City, State)',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a pool address';
                              }
                              return null;
                            },
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TypeAheadField<String>(
                            controller: _customerController,
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Customer Name',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: customerViewModel.isLoading 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a customer';
                                  }
                                  if (!customerNames.contains(value)) {
                                    return 'Please select a valid customer';
                                  }
                                  return null;
                                },
                              );
                            },
                            suggestionsCallback: (pattern) {
                              if (customerViewModel.isLoading || customerNames.isEmpty) {
                                return <String>[];
                              }
                              if (pattern.isEmpty) {
                                return customerNames.toList();
                              }
                              return customerNames.where((option) => option.toLowerCase().contains(pattern.toLowerCase())).toList();
                            },
                            itemBuilder: (context, String suggestion) {
                              return ListTile(
                                title: Text(suggestion),
                              );
                            },
                            onSelected: (String selectedName) {
                              setState(() {
                                _selectedCustomerName = selectedName;
                                _customerController.text = selectedName;
                                final customer = customers.firstWhere((c) => c.name == selectedName);
                                _selectedCustomerId = customer.id;
                                _selectedCustomerEmail = customer.email;
                              });
                            },
                            emptyBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('No matching customers found.'),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          AppTextField(
                            controller: _sizeController,
                            label: 'Pool Size',
                            hint: 'Enter pool dimensions (e.g., 25ft x 15ft)',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter pool size';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          AppTextField(
                            controller: _monthlyCostController,
                            label: 'Monthly Maintenance Cost',
                            hint: 'Enter monthly maintenance cost (e.g., 150.00)',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final cost = double.tryParse(value);
                                if (cost == null || cost < 0) {
                                  return 'Please enter a valid cost amount';
                                }
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
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _statusOptions.map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status[0].toUpperCase() + status.substring(1),
                                        style: const TextStyle(color: AppColors.primary),
                                      ),
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
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Pool Type',
                              labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _typeOptions.map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: const TextStyle(color: AppColors.primary),
                                      ),
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
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                            value: _selectedWaterQuality,
                            decoration: InputDecoration(
                              labelText: 'Water Quality',
                              labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _waterQualityOptions.map((quality) => DropdownMenuItem(
                                      value: quality,
                                      child: Text(
                                        quality[0].toUpperCase() + quality.substring(1),
                                        style: const TextStyle(color: AppColors.primary),
                                      ),
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
                          Builder(
                            builder: (context) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color.fromRGBO(33, 150, 243, 0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppTextField(
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
                              );
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
                            label: _isLoading 
                              ? 'Processing...'
                              : (_isEditing ? 'Update' : 'Save'),
                            onPressed: _isLoading ? null : _savePool,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (_uploadedImageUrl != null) {
      // Handle both network URLs and data URLs
      if (_uploadedImageUrl!.startsWith('data:image/')) {
        // It's a data URL, extract the base64 part
        try {
          final base64Data = _uploadedImageUrl!.split(',')[1];
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        } catch (e) {
          print('Error decoding pool photo data URL: $e');
          return null;
        }
      } else {
        // It's a network URL
        return NetworkImage(_uploadedImageUrl!);
      }
    } else {
      return null;
    }
  }

  bool _hasSelectedImage() {
    return _selectedImageBytes != null || _uploadedImageUrl != null;
  }

  // Parse pool size from text (e.g., "40x30" -> area calculation or just first number)
  double _parseSize(String sizeText) {
    if (sizeText.isEmpty) return 0.0;
    
    // Try to parse as direct number first
    final directParse = double.tryParse(sizeText);
    if (directParse != null) return directParse;
    
    // Try to parse dimensions like "40x30"
    if (sizeText.contains('x') || sizeText.contains('X')) {
      final parts = sizeText.toLowerCase().split('x');
      if (parts.length == 2) {
        final width = double.tryParse(parts[0].trim());
        final height = double.tryParse(parts[1].trim());
        if (width != null && height != null) {
          return width * height; // Return area
        }
      }
    }
    
    // Extract first number if format is mixed (e.g., "40m x 30m")
    final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(sizeText);
    if (numberMatch != null) {
      return double.tryParse(numberMatch.group(1)!) ?? 0.0;
    }
    
    return 0.0;
  }

  Future<void> _loadMissingCustomerName() async {
    if (_selectedCustomerId != null && _selectedCustomerName == null) {
      final customerViewModel = Provider.of<CustomerViewModel>(context, listen: false);
      await customerViewModel.loadCustomerName(_selectedCustomerId!);
      if (mounted) {
        setState(() {
          _selectedCustomerName = customerViewModel.customerName;
          _customerController.text = customerViewModel.customerName ?? '';
        });
      }
    }
  }
} 