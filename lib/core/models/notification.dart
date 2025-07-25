import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  system,
  maintenance,
  alert,
  info,
  breakRequest,
  invitation,
  assignment,
  route,
  customer,
  billing,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String recipientId;
  final String recipientRole;
  final String? companyId;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? actionText;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.recipientId,
    required this.recipientRole,
    this.companyId,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.data,
    this.actionUrl,
    this.actionText,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type'] ?? 'info'),
      priority: _parseNotificationPriority(data['priority'] ?? 'medium'),
      recipientId: data['recipientId'] ?? '',
      recipientRole: data['recipientRole'] ?? '',
      companyId: data['companyId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      data: data['data'],
      actionUrl: data['actionUrl'],
      actionText: data['actionText'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'actionUrl': actionUrl,
      'actionText': actionText,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? recipientId,
    String? recipientRole,
    String? companyId,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionText,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'system':
        return NotificationType.system;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'alert':
        return NotificationType.alert;
      case 'breakRequest':
        return NotificationType.breakRequest;
      case 'invitation':
        return NotificationType.invitation;
      case 'assignment':
        return NotificationType.assignment;
      case 'route':
        return NotificationType.route;
      case 'customer':
        return NotificationType.customer;
      case 'billing':
        return NotificationType.billing;
      default:
        return NotificationType.info;
    }
  }

  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'critical':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.medium;
    }
  }

  Color get priorityColor {
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

  IconData get typeIcon {
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
} 