import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/notification.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_card.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({Key? key}) : super(key: key);

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  NotificationType _selectedType = NotificationType.info;
  NotificationPriority _selectedPriority = NotificationPriority.medium;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Set default values
    _titleController.text = 'Test Notification';
    _messageController.text =
        'This is a test notification to verify the system is working.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Test Notification',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message field
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  DropdownButtonFormField<NotificationType>(
                    decoration: const InputDecoration(
                      labelText: 'Notification Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedType,
                    items: NotificationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getTypeIcon(type),
                              color: _getTypeColor(type),
                            ),
                            const SizedBox(width: 8),
                            Text(type.name.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority selector
                  DropdownButtonFormField<NotificationPriority>(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPriority,
                    items: NotificationPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getPriorityColor(priority),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(priority.name.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPriority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _isCreating
                          ? 'Creating...'
                          : 'Create Test Notification',
                      onPressed: _isCreating ? null : _createTestNotification,
                      isLoading: _isCreating,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick test buttons
            Text(
              'Quick Tests',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickTestButton(
                  'System Alert',
                  'System maintenance scheduled',
                  NotificationType.system,
                  NotificationPriority.high,
                ),
                _buildQuickTestButton(
                  'Break Request',
                  'Worker requesting break',
                  NotificationType.breakRequest,
                  NotificationPriority.high,
                ),
                _buildQuickTestButton(
                  'Maintenance',
                  'Pool maintenance completed',
                  NotificationType.maintenance,
                  NotificationPriority.medium,
                ),
                _buildQuickTestButton(
                  'Assignment',
                  'New route assigned',
                  NotificationType.assignment,
                  NotificationPriority.medium,
                ),
                _buildQuickTestButton(
                  'Critical Alert',
                  'Emergency situation detected',
                  NotificationType.alert,
                  NotificationPriority.critical,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButton(
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) {
    return AppButton(
      label: title,
      onPressed: () => _createQuickTest(title, message, type, priority),
      isOutlined: true,
      color: _getTypeColor(type),
    );
  }

  Future<void> _createTestNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final notificationService = context.read<NotificationService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final notificationId = await notificationService.createUserNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        recipientId: currentUser.id,
        recipientRole: currentUser.role.name,
        companyId: currentUser.companyId,
        type: _selectedType,
        priority: _selectedPriority,
      );

      if (notificationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.text = 'Test Notification';
        _messageController.text =
            'This is a test notification to verify the system is working.';
        setState(() {
          _selectedType = NotificationType.info;
          _selectedPriority = NotificationPriority.medium;
        });
      } else {
        throw Exception('Failed to create notification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _createQuickTest(
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) async {
    try {
      final notificationService = context.read<NotificationService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final notificationId = await notificationService.createUserNotification(
        title: title,
        message: message,
        recipientId: currentUser.id,
        recipientRole: currentUser.role.name,
        companyId: currentUser.companyId,
        type: type,
        priority: priority,
      );

      if (notificationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title notification created!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to create notification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods for notification types and priorities
  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.alert:
        return Icons.warning;
      case NotificationType.breakRequest:
        return Icons.coffee;
      case NotificationType.invitation:
        return Icons.person_add;
      case NotificationType.assignment:
        return Icons.assignment;
      case NotificationType.route:
        return Icons.route;
      case NotificationType.customer:
        return Icons.person;
      case NotificationType.billing:
        return Icons.payment;
      case NotificationType.info:
        return Icons.info;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.maintenance:
        return Colors.blue;
      case NotificationType.alert:
        return Colors.orange;
      case NotificationType.breakRequest:
        return Colors.purple;
      case NotificationType.invitation:
        return Colors.green;
      case NotificationType.assignment:
        return Colors.indigo;
      case NotificationType.route:
        return Colors.teal;
      case NotificationType.customer:
        return Colors.cyan;
      case NotificationType.billing:
        return Colors.amber;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.critical:
        return Colors.red;
    }
  }
}
