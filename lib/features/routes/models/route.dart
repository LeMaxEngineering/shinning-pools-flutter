import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String companyId;
  final String routeName;
  final List<String> stops; // List of pool IDs
  final String status; // e.g., 'created', 'in_progress', 'completed'
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startTime;
  final DateTime? endTime;

  RouteModel({
    required this.id,
    required this.companyId,
    required this.routeName,
    required this.stops,
    required this.status,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
  });

  // Helper method to safely convert date fields (handles both Timestamp and String)
  static DateTime? _safeDateTime(dynamic value) {
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

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      routeName: data['routeName'] ?? '',
      stops: List<String>.from(data['stops'] ?? []),
      status: data['status'] ?? 'ACTIVE',
      notes: data['notes'] ?? '',
      createdAt: _safeDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _safeDateTime(data['updatedAt']) ?? DateTime.now(),
      startTime: _safeDateTime(data['startTime']),
      endTime: _safeDateTime(data['endTime']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'routeName': routeName,
      'stops': stops,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 