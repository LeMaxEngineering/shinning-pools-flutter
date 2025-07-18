import 'package:flutter/material.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/colors.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_card.dart';
import 'package:shinning_pools_flutter/features/users/screens/profile_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/user_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/user_initials_avatar.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/help_drawer.dart';
import '../../routes/screens/route_creation_screen.dart';

class RootDashboard extends StatefulWidget {
  const RootDashboard({super.key});

  @override
  State<RootDashboard> createState() => _RootDashboardState();
}

class _RootDashboardState extends State<RootDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfileTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _onUserManagementTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
    );
  }

  void _showAddBillingPlanDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    final _descriptionController = TextEditingController();
    String _selectedPeriod = 'Monthly';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Billing Plan'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a plan name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.primary,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Billing Period',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.primary,
                      ),
                      items: ['Monthly', 'Quarterly', 'Yearly']
                          .map((period) => DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // TODO: Implement billing plan creation service
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Billing plan created successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating billing plan: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    List<String> _selectedPermissions = [];
    bool _isLoading = false;

    final availablePermissions = [
      'Manage Users',
      'Manage Pools',
      'Manage Routes',
      'View Reports',
      'Manage Billing',
      'System Settings',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add User Profile'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Profile Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a profile name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...availablePermissions.map((permission) => CheckboxListTile(
                      title: Text(permission, style: TextStyle(color: Colors.black87)),
                      value: _selectedPermissions.contains(permission),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPermissions.add(permission);
                          } else {
                            _selectedPermissions.remove(permission);
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // TODO: Implement profile creation service
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile created successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating profile: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, String profileName) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: profileName);
    final _descriptionController = TextEditingController();
    List<String> _selectedPermissions = ['Manage Users', 'Manage Pools']; // Default permissions
    bool _isLoading = false;

    final availablePermissions = [
      'Manage Users',
      'Manage Pools',
      'Manage Routes',
      'View Reports',
      'Manage Billing',
      'System Settings',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Profile: $profileName'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Profile Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a profile name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Text('Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...availablePermissions.map((permission) => CheckboxListTile(
                      title: Text(permission, style: TextStyle(color: Colors.black87)),
                      value: _selectedPermissions.contains(permission),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPermissions.add(permission);
                          } else {
                            _selectedPermissions.remove(permission);
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // TODO: Implement profile update service
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating profile: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMaintenanceTypeDialog(BuildContext context, String type) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: type);
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Maintenance Type: $type'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a maintenance type';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // TODO: Implement maintenance type update service
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Maintenance type updated successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating maintenance type: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteMaintenanceTypeDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Maintenance Type: $type'),
          content: const Text('Are you sure you want to delete this maintenance type?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement delete type
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maintenance type deleted successfully!'),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMaintenanceTypeDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Maintenance Type'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a maintenance type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              // TODO: Implement maintenance type creation service
                              await Future.delayed(const Duration(seconds: 1));
                              
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Maintenance type created successfully!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error creating maintenance type: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    // Mock notifications data
    final notifications = [
      {
        'title': 'New Company Registration',
        'message': 'PoolCare Solutions has registered for a trial account',
        'time': '2 hours ago',
        'type': 'info',
      },
      {
        'title': 'System Update',
        'message': 'Scheduled maintenance completed successfully',
        'time': '1 day ago',
        'type': 'success',
      },
      {
        'title': 'Billing Alert',
        'message': '3 companies have overdue payments',
        'time': '2 days ago',
        'type': 'warning',
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications),
              const SizedBox(width: 8),
              const Text('Notifications'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Implement mark all as read
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                },
                child: const Text('Mark All Read'),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No notifications'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getNotificationIcon(notification['type']),
                            color: _getNotificationColor(notification['type']),
                          ),
                          title: Text(
                            notification['title'] ?? 'Notification',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['message'] ?? 'No message', style: TextStyle(color: AppColors.textPrimary)),
                              Text(
                                notification['time'] ?? 'Unknown time',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              // TODO: Implement dismiss notification
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Notification dismissed')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildAccountsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accounts Management',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          // Active Accounts Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Accounts',
                          style: AppTextStyles.subtitle,
                        ),
                        Text(
                          '0',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_business),
                      onPressed: () {
                        // Navigate to company creation screen
                        Navigator.of(context).pushNamed('/createCompany');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.view_list),
                    label: const Text('View All Companies'),
                    onPressed: () {
                      // Navigate to companies list screen
                      Navigator.of(context).pushNamed('/companiesList');
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Manage Applications'),
                    onPressed: () {
                      // Navigate to company management screen
                      Navigator.of(context).pushNamed('/companyManagement');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Billing Plans Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing Plans',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Plans: 0',
                      style: AppTextStyles.body,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Plan'),
                      onPressed: () {
                        _showAddBillingPlanDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Profiles',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Profiles',
                      style: AppTextStyles.subtitle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () {
                        _showAddProfileDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Profile list placeholder
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final profiles = ['Root', 'Administrator', 'Worker'];
                    return ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: Text(profiles[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditProfileDialog(context, profiles[index]);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Catalog',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maintenance Types',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 16),
                // Maintenance types list placeholder
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final types = [
                      'Physical Cleaning',
                      'Chemical Treatment',
                      'Filter Maintenance'
                    ];
                    return ListTile(
                      title: Text(types[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditMaintenanceTypeDialog(context, types[index]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              _showDeleteMaintenanceTypeDialog(context, types[index]);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Maintenance Type'),
                    onPressed: () {
                      _showAddMaintenanceTypeDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Users',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage user roles and permissions across the platform. Only root users can access this section.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('Manage Users'),
                    onPressed: _onUserManagementTapped,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/img/icon.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Root Dashboard',
              style: AppTextStyles.subtitle.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotificationsDialog(context);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Builder(
              builder: (context) {
                final currentUser = Provider.of<AuthService>(context).currentUser;
                return GestureDetector(
                  onTap: _onProfileTapped,
                  child: UserInitialsAvatar(
                    displayName: currentUser?.name,
                    email: currentUser?.email,
                    photoUrl: currentUser?.photoUrl,
                    radius: 20,
                    fontSize: 18,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: const HelpDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAccountsSection(),
          _buildProfilesSection(),
          _buildCatalogSection(),
          _buildUserManagementSection(),
          // Add RouteCreationScreen as the new tab
          const RouteCreationScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Profiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'User Management',
          ),
          // Add the new Routes tab
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
} 