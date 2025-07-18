import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Assignment {
  final String id;
  final String routeId;
  final String workerId;
  final String? routeName;
  final String? workerName;
  final DateTime assignedAt;
  final DateTime? routeDate;
  final String status;
  final String companyId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Assignment({
    required this.id,
    required this.routeId,
    required this.workerId,
    this.routeName,
    this.workerName,
    required this.assignedAt,
    this.routeDate,
    this.status = 'Active',
    required this.companyId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Helper method to safely convert date fields (handles both Timestamp and String)
  static DateTime _safeDateTime(dynamic value, DateTime defaultValue) {
    if (value == null) return defaultValue;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Warning: Could not parse date string: $value');
        return defaultValue;
      }
    }
    if (value is DateTime) return value;
    print('Warning: Unexpected date type: ${value.runtimeType} for value: $value');
    return defaultValue;
  }

  // Helper method to safely convert optional date fields
  static DateTime? _safeDateTimeOptional(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Warning: Could not parse date string: $value');
        return null;
      }
    }
    if (value is DateTime) return value;
    print('Warning: Unexpected date type: ${value.runtimeType} for value: $value');
    return null;
  }

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle both userId and workerId for backward compatibility
    String workerId = data['workerId'] ?? data['userId'] ?? '';
    
    return Assignment(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      workerId: workerId,
      routeName: data['routeName'],
      workerName: data['workerName'],
      assignedAt: _safeDateTime(data['assignedAt'], DateTime.now()),
      routeDate: _safeDateTimeOptional(data['routeDate']),
      status: data['status'] ?? 'Active',
      companyId: data['companyId'] ?? '',
      notes: data['notes'],
      createdAt: _safeDateTimeOptional(data['createdAt']),
      updatedAt: _safeDateTimeOptional(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'workerId': workerId,
      'routeName': routeName,
      'workerName': workerName,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'routeDate': routeDate != null ? Timestamp.fromDate(routeDate!) : null,
      'status': status,
      'companyId': companyId,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Check if assignment is historical
  bool get isHistorical {
    final statusLower = status.toLowerCase();
    // Explicitly historical statuses
    if (statusLower == 'historical' ||
        statusLower == 'completed' ||
        statusLower == 'cancelled' ||
        statusLower == 'closed' ||
        statusLower == 'no executed') {
      return true;
    }
    // Date-based historical logic (but exclude Hold status)
    if (statusLower != 'hold' &&
        routeDate != null &&
        routeDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return true;
    }
    return false;
  }

  // Format route date
  String get formattedRouteDate {
    return routeDate != null ? DateFormat('MMMM dd, yyyy').format(routeDate!) : 'N/A';
  }
} 