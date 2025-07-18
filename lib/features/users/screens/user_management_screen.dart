import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_management_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_background.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  bool _isChangingRole = false;
  String _selectedRole = 'customer';
  List<String> _roleOptions = ['root', 'admin', 'worker', 'customer'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await _userManagementService.listUsers();
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeUserRole(String userId, String currentRole, String newRole) async {
    try {
      setState(() {
        _isChangingRole = true;
      });

      final success = await _userManagementService.changeUserRole(userId, newRole);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User role changed successfully to ${_userManagementService.getRoleDisplayName(newRole)}'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload users to reflect changes
          await _loadUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to change user role'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing user role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingRole = false;
        });
      }
    }
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    final currentRole = user['role'] as String? ?? 'customer';
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Change Role for ${user['email']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Role: ${_userManagementService.getRoleDisplayName(currentRole)}',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: _roleOptions.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val ?? _roleOptions.first),
                    dropdownColor: AppColors.primary,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.primary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color.fromRGBO(59, 130, 246, 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Change Role',
                  isLoading: _isChangingRole,
                  onPressed: _selectedRole == currentRole
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _changeUserRole(user['uid'], currentRole, _selectedRole);
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUsers,
          ),
        ],
      ),
      body: AppBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildUsersList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: AppTextStyles.body),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: _loadUsers,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found', style: AppTextStyles.body),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final role = user['role'] as String? ?? 'customer';
        final email = user['email'] as String? ?? 'Unknown';
        final displayName = user['displayName'] as String? ?? email.split('@').first;
        final isCurrentUser = user['uid'] == context.read<AuthService>().currentUser?.id;

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              displayName,
              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userManagementService.getRoleDisplayName(role),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: isCurrentUser
                ? const Chip(
                    label: Text('Current User'),
                    backgroundColor: AppColors.primary,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showChangeRoleDialog(user),
                  ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'root':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'worker':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 