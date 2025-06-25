import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
}

class WorkerInvitation {
  final String id;
  final String companyId;
  final String companyName;
  final String invitedUserEmail;
  final String invitedUserId;
  final String invitedByUserId;
  final String invitedByUserName;
  final InvitationStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final bool isSeenByAdmin;

  WorkerInvitation({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.invitedUserEmail,
    required this.invitedUserId,
    required this.invitedByUserId,
    required this.invitedByUserName,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    this.isSeenByAdmin = false,
  });

  // Create from Firestore document
  factory WorkerInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return WorkerInvitation(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      invitedUserEmail: data['invitedUserEmail'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      invitedByUserId: data['invitedByUserId'] ?? '',
      invitedByUserName: data['invitedByUserName'] ?? '',
      status: _parseStatus(data['status'] ?? 'pending'),
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      isSeenByAdmin: data['isSeenByAdmin'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'invitedUserEmail': invitedUserEmail,
      'invitedUserId': invitedUserId,
      'invitedByUserId': invitedByUserId,
      'invitedByUserName': invitedByUserName,
      'status': status.name,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isSeenByAdmin': isSeenByAdmin,
    };
  }

  // Create a copy with updated fields
  WorkerInvitation copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? invitedUserEmail,
    String? invitedUserId,
    String? invitedByUserId,
    String? invitedByUserName,
    InvitationStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    bool? isSeenByAdmin,
  }) {
    return WorkerInvitation(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedByUserName: invitedByUserName ?? this.invitedByUserName,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isSeenByAdmin: isSeenByAdmin ?? this.isSeenByAdmin,
    );
  }

  // Parse status from string
  static InvitationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }

  // Check if invitation is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Get status display name
  String get statusDisplay {
    switch (status) {
      case InvitationStatus.pending:
        return isExpired ? 'Expired' : 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case InvitationStatus.pending:
        return isExpired ? Colors.red : Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.rejected:
        return Colors.red;
      case InvitationStatus.expired:
        return Colors.red;
    }
  }

  @override
  String toString() {
    return 'WorkerInvitation(id: $id, email: $invitedUserEmail, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkerInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 