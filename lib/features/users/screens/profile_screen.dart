import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/navigation_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
            _displayNameController = TextEditingController(text: _userData!['displayName'] ?? '');
            _emailController = TextEditingController(text: _userData!['email'] ?? '');
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'User data not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading user data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'displayName': _displayNameController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'root':
        return 'Root Administrator';
      case 'admin':
        return 'Company Administrator';
      case 'worker':
        return 'Worker';
      case 'customer':
        return 'Customer';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error', style: AppTextStyles.body),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: _loadUserData,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                setState(() => _isEditing = true);
              } else if (value == 'logout') {
                final authService = context.read<AuthService>();
              final shouldSignOut = await showDialog<bool>(
                context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
              );

              if (shouldSignOut == true) {
              await authService.signOut();
                  if (mounted) {
                    context
                        .read<NavigationService>()
                        .navigateToLogin(context);
                }
              }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (!_isEditing)
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Profile'),
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: _userData!['photoUrl'] != null && _userData!['photoUrl'].isNotEmpty
                    ? NetworkImage(_userData!['photoUrl'])
                    : null,
                child: (_userData!['photoUrl'] == null || _userData!['photoUrl'].isEmpty)
                    ? const Icon(Icons.account_circle, size: 80, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(height: 24),

              // Display Name
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display Name', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      AppTextField(
                        controller: _displayNameController,
                        label: 'Display Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      )
                    else
                      Text(
                        _userData!['displayName'] ?? 'No display name',
                        style: AppTextStyles.body,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Email
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _userData!['email'] ?? 'No email',
                            style: AppTextStyles.body,
                          ),
                        ),
                        if (_userData!['emailVerified'] == true)
                          const Icon(Icons.verified, color: Colors.green, size: 20)
                        else
                          const Icon(Icons.warning, color: Colors.orange, size: 20),
                      ],
                    ),
                    if (_userData!['emailVerified'] != true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Email not verified',
                          style: AppTextStyles.caption.copyWith(color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Role
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Role', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Text(
                      _getRoleDisplayName(_userData!['role'] ?? 'unknown'),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Company ID
              if (_userData!['companyId'] != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Company ID', style: AppTextStyles.subtitle),
                      const SizedBox(height: 8),
                      Text(
                        _userData!['companyId'],
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _displayNameController.text = _userData!['displayName'] ?? '';
                          });
                        },
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        onPressed: _saveChanges,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 