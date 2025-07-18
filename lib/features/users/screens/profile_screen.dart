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
import '../models/worker.dart';
import '../viewmodels/worker_viewmodel.dart';

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

                if (shouldSignOut == true && mounted) {
                  try {
                    await authService.signOut();
                    if (mounted) {
                      context
                          .read<NavigationService>()
                          .navigateToLogin(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                backgroundColor: Colors.white,
                backgroundImage: (_userData!['photoUrl'] != null && _userData!['photoUrl'].isNotEmpty)
                    ? NetworkImage(_userData!['photoUrl'])
                    : null,
                child: (_userData!['photoUrl'] == null || _userData!['photoUrl'].isEmpty)
                    ? _buildInitialsAvatar(_userData!)
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

              // Worker-specific sections
              if (_userData!['role'] == 'worker') ...[
                const SizedBox(height: 16),
                _buildWorkerPerformanceSection(),
                const SizedBox(height: 16),
                _buildWorkerStatusSection(),
                const SizedBox(height: 16),
                _buildWorkHistorySection(),
              ],

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

  Widget _buildWorkerPerformanceSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Performance Metrics', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Rating',
                  '4.8',
                  Icons.star,
                  Colors.amber,
                  'out of 5.0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Pools Assigned',
                  '12',
                  Icons.pool,
                  Colors.blue,
                  'this month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  '95%',
                  Icons.check_circle,
                  Colors.green,
                  'last 30 days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Avg Time',
                  '45m',
                  Icons.timer,
                  Colors.purple,
                  'per pool',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.subtitle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerStatusSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Work Status', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip('Available', Colors.green, 'available'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('On Route', Colors.blue, 'on_route'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('Busy', Colors.orange, 'busy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusChip('Break', Colors.purple, 'break'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('Off Duty', Colors.grey, 'off_duty'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(), // Empty space for alignment
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(59, 130, 246, 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your status helps managers assign work efficiently',
                    style: AppTextStyles.caption.copyWith(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, String status) {
    final isSelected = _userData!['status'] == status;
    return InkWell(
      onTap: () => _updateWorkerStatus(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Color.fromRGBO(59, 130, 246, 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _updateWorkerStatus(String status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _userData!['status'] = status;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to: ${status.replaceAll('_', ' ').toUpperCase()}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWorkHistorySection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Recent Work History', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildWorkHistoryItem(
            'Villa Pool #1',
            'Completed maintenance',
            '2 hours ago',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildWorkHistoryItem(
            'Hotel Pool #3',
            'Started maintenance',
            '4 hours ago',
            Icons.play_circle,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildWorkHistoryItem(
            'Residential Pool #5',
            'Completed maintenance',
            '1 day ago',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildWorkHistoryItem(
            'Apartment Pool #2',
            'Completed maintenance',
            '2 days ago',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Full work history coming soon!')),
                );
              },
              child: Text(
                'View Full History',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHistoryItem(String title, String description, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(59, 130, 246, 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromRGBO(59, 130, 246, 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(Map<String, dynamic> userData) {
    String initials = '';
    if (userData['displayName'] != null && userData['displayName'].toString().trim().isNotEmpty) {
      final parts = userData['displayName'].toString().trim().split(' ');
      if (parts.length == 1) {
        initials = parts[0][0];
      } else if (parts.length > 1) {
        initials = parts[0][0] + parts[1][0];
      }
    } else if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      initials = userData['email'][0];
    }
    if (initials.isEmpty) {
      initials = '?';
    }
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.blue, // Contrasting color for visibility
        ),
      ),
    );
  }
} 