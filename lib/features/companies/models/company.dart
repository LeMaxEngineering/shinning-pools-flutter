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
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      requestDate: (data['requestDate'] as Timestamp? ?? Timestamp.now()).toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      suspendedAt: (data['suspendedAt'] as Timestamp?)?.toDate(),
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
      case 'approved':
        return CompanyStatus.approved;
      case 'rejected':
        return CompanyStatus.rejected;
      case 'suspended':
        return CompanyStatus.suspended;
      case 'inactive':
        return CompanyStatus.inactive;
      case 'pending':
      default:
        return CompanyStatus.pending;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CompanyStatus.approved:
        return 'Approved';
      case CompanyStatus.rejected:
        return 'Rejected';
      case CompanyStatus.suspended:
        return 'Suspended';
      case CompanyStatus.inactive:
        return 'Inactive';
      case CompanyStatus.pending:
      default:
        return 'Pending';
    }
  }

  bool get isPending => status == CompanyStatus.pending;
  bool get isApproved => status == CompanyStatus.approved;
  bool get isRejected => status == CompanyStatus.rejected;
  bool get isSuspended => status == CompanyStatus.suspended;
  bool get isInactive => status == CompanyStatus.inactive;
} 