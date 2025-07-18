import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/worker.dart';
import '../viewmodels/worker_viewmodel.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../../../shared/ui/widgets/app_background.dart';

class WorkerEditScreen extends StatefulWidget {
  final Worker worker;
  const WorkerEditScreen({super.key, required this.worker});

  @override
  State<WorkerEditScreen> createState() => _WorkerEditScreenState();
}

class _WorkerEditScreenState extends State<WorkerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _status;
  bool _isLoading = false;

  // Photo upload related
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  UploadTask? _currentUploadTask;
  bool _isUploading = false;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _phoneController = TextEditingController(text: widget.worker.phone);
    _emailController = TextEditingController(text: widget.worker.email);
    _status = widget.worker.status;
    _uploadedImageUrl = widget.worker.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        setState(() {
          _selectedImageBytes = bytes;
          _photoRemoved = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image:  [31m${e.toString()} [0m')),
      );
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImageBytes == null) return null;

    // Handle CORS issues in development mode
    if (kDebugMode && kIsWeb) {
      print('Development mode: Using data URL for worker photo...');
      
      // Create data URL for development mode
      final base64String = base64Encode(_selectedImageBytes!);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      // Check size limit (data URLs have overhead)
      if (dataUrl.length > 900000) {
        print('Worker photo too large (${dataUrl.length} bytes), skipping...');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo too large for development mode - worker saved without photo'),
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

    if (!mounted) return null; // Check if widget is still mounted
    
    setState(() { _isUploading = true; });
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageRef = storageRef.child('workers/worker_$timestamp.jpg');
      final uploadTask = imageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      _currentUploadTask = uploadTask;
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
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
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: ${e.message}');
      _currentUploadTask = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload timed out - worker will be saved without photo changes'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return null;
    } on FirebaseException catch (e) {
      print('Firebase upload error: ${e.code} - ${e.message}');
      _currentUploadTask = null;
      if (mounted) {
        // For CORS or permission errors, continue without photo
        if (e.code.contains('cors') || e.code.contains('unauthorized') || e.code.contains('storage')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo upload not available - worker data will be saved'),
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
      _currentUploadTask = null;
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
              content: Text('Photo upload blocked by browser security - worker data will be saved'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return null; // Continue without photo
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed - worker data will be saved'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return null; // Continue without photo
      }
      return null;
    } finally {
      if (mounted) setState(() { _isUploading = false; });
    }
    return null;
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (_uploadedImageUrl != null && !_photoRemoved) {
      if (_uploadedImageUrl!.startsWith('data:image/')) {
        try {
          final base64Data = _uploadedImageUrl!.split(',')[1];
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        } catch (e) {
          return null;
        }
      } else {
        return NetworkImage(_uploadedImageUrl!);
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return; // Check if widget is still mounted
    
    setState(() => _isLoading = true);
    
    try {
      final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
      String? photoUrl;
      
      if (_selectedImageBytes != null) {
        photoUrl = await _uploadImageToFirebase();
      } else if (!_photoRemoved) {
        photoUrl = _uploadedImageUrl;
      } else {
        photoUrl = null;
      }
      
      if (!mounted) return; // Check again after async operation
      
      final success = await viewModel.updateWorker(
        widget.worker.id,
        {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'status': _status,
          'photoUrl': photoUrl,
        },
      );
      
      if (!mounted) return; // Check again after async operation
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.error), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error saving worker: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving worker: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Worker')),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker Photo Section
                  Center(
                    child: Stack(
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
                              if (_uploadedImageUrl != null) {
                                _photoRemoved = true;
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
                        'Photo selected ( ${(_selectedImageBytes!.length / 1024).round()} KB)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) => value == null || value.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty ? 'Phone required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'on_route', child: Text('On Route')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                    dropdownColor: Colors.white,
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: AppButton(
                      label: _isLoading ? 'Saving...' : 'Save',
                      onPressed: _isLoading ? null : _save,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 