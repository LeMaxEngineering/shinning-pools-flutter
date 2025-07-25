import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationType? _selectedType;
  NotificationPriority? _selectedPriority;
  bool _showUnreadOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Start listening for notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().startListening();
    });
  }

  @override
  void dispose() {
    // Stop listening when screen is disposed
    context.read<NotificationService>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              final unreadCount = notificationService.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _showFilterDialog,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark All Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_access',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Test Access'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_test',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create Test Notification'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Consumer<NotificationService>(
              builder: (context, notificationService, child) {
                if (notificationService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (notificationService.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificationService.error!,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          onPressed: () {
                            notificationService.clearError();
                            notificationService.startListening();
                          },
                          label: 'Retry',
                        ),
                      ],
                    ),
                  );
                }

                final filteredNotifications = _getFilteredNotifications(
                  notificationService.notifications,
                );

                if (filteredNotifications.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    notificationService.startListening();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationCard(
                        notification,
                        notificationService,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search notifications...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Filter controls
          Row(
            children: [
              // Unread Only checkbox
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showUnreadOnly,
                        onChanged: (value) {
                          setState(() {
                            _showUnreadOnly = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text(
                        'Unread Only',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              // Notification Type dropdown
              Expanded(
                child: DropdownButtonFormField<NotificationType?>(
                  decoration: const InputDecoration(
                    labelText: 'Notification Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: _selectedType,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...NotificationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppTextStyles.subtitle.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    NotificationService service,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification, service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  notification.typeIcon,
                  color: notification.priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.priorityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: notification.priorityColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.priority.name.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: notification.priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action button
              if (notification.actionText != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _handleNotificationAction(notification),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(
    List<AppNotification> notifications,
  ) {
    return notifications.where((notification) {
      // Filter by unread status
      if (_showUnreadOnly && notification.isRead) {
        return false;
      }

      // Filter by type
      if (_selectedType != null && notification.type != _selectedType) {
        return false;
      }

      // Filter by priority
      if (_selectedPriority != null &&
          notification.priority != _selectedPriority) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return notification.title.toLowerCase().contains(query) ||
            notification.message.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(
    AppNotification notification,
    NotificationService service,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      service.markAsRead(notification.id);
    }

    // Show notification details
    _showNotificationDetails(notification);
  }

  void _handleNotificationAction(AppNotification notification) {
    // Handle action button tap
    if (notification.actionUrl != null) {
      // Navigate to action URL
      print('Navigate to: ${notification.actionUrl}');
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.typeIcon, color: notification.priorityColor),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message, style: AppTextStyles.body),
              const SizedBox(height: 16),
              Text(
                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(notification.createdAt)}',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              ),
              if (notification.readAt != null)
                Text(
                  'Read: ${DateFormat('MMM dd, yyyy HH:mm').format(notification.readAt!)}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (notification.actionText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleNotificationAction(notification);
              },
              child: Text(notification.actionText!),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority filter
            DropdownButtonFormField<NotificationPriority>(
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              value: _selectedPriority,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Priorities'),
                ),
                ...NotificationPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Type filter
            DropdownButtonFormField<NotificationType>(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              value: _selectedType,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedPriority = null;
                _showUnreadOnly = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    final service = context.read<NotificationService>();

    switch (action) {
      case 'mark_all_read':
        await service.markAllAsRead();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read')),
          );
        }
        break;
      case 'clear_all':
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to delete all notifications? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear All'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // Delete all notifications
          for (final notification in service.notifications) {
            await service.deleteNotification(notification.id);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All notifications cleared')),
            );
          }
        }
        break;
      case 'test_access':
        final success = await service.testFirestoreAccess();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Firestore access test successful'
                    : 'Firestore access test failed',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
        break;
      case 'create_test':
        final notificationId = await service.createTestNotification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notificationId != null
                    ? 'Test notification created'
                    : 'Failed to create test notification',
              ),
              backgroundColor: notificationId != null
                  ? Colors.green
                  : Colors.red,
            ),
          );
        }
        break;
    }
  }
}
