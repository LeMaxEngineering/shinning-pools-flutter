// This file will define the Company data model.

import 'package:cloud_firestore/cloud_firestore.dart';

enum CompanyStatus { pending, approved, rejected, suspended, inactive }

class Company {
  final String id;
  final String name;
  final String ownerId;
  final String ownerEmail;
  final CompanyStatus status;
  final String? address;
  final String? phone;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime requestDate;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? suspendedAt;
  final String? rejectionReason;
  final String? suspensionReason;

  Company({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerEmail,
    required this.status,
    this.address,
    this.phone,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.requestDate,
    this.approvedAt,
    this.rejectedAt,
    this.suspendedAt,
    this.rejectionReason,
    this.suspensionReason,
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

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      status: _statusFromString(data['status']),
      address: data['address'],
      phone: data['phone'],
      description: data['description'],
      createdAt: _safeDateTime(data['createdAt'], DateTime.now()),
      updatedAt: _safeDateTime(data['updatedAt'], DateTime.now()),
      requestDate: _safeDateTime(data['requestDate'], DateTime.now()),
      approvedAt: _safeDateTimeOptional(data['approvedAt']),
      rejectedAt: _safeDateTimeOptional(data['rejectedAt']),
      suspendedAt: _safeDateTimeOptional(data['suspendedAt']),
      rejectionReason: data['rejectionReason'],
      suspensionReason: data['suspensionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'status': status.name,
      'address': address,
      'phone': phone,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'requestDate': Timestamp.fromDate(requestDate),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'suspendedAt': suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'rejectionReason': rejectionReason,
      'suspensionReason': suspensionReason,
    };
  }

  static CompanyStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return CompanyStatus.pending;
      case 'approved':
        return CompanyStatus.approved;
      case 'rejected':
        return CompanyStatus.rejected;
      case 'suspended':
        return CompanyStatus.suspended;
      case 'inactive':
        return CompanyStatus.inactive;
      default:
        return CompanyStatus.pending;
    }
  }

  String get statusDisplay {
    switch (status) {
      case CompanyStatus.pending:
        return 'Pending';
      case CompanyStatus.approved:
        return 'Approved';
      case CompanyStatus.rejected:
        return 'Rejected';
      case CompanyStatus.suspended:
        return 'Suspended';
      case CompanyStatus.inactive:
        return 'Inactive';
    }
  }

  // Alias for UI compatibility
  String get statusDisplayName => statusDisplay;

  @override
  String toString() {
    return 'Company(id: $id, name: $name, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}