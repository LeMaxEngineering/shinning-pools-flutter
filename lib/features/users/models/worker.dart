import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String companyId;
  final String status;
  final int poolsAssigned;
  final double rating;
  final String? photoUrl;
  final DateTime lastActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.companyId,
    required this.status,
    required this.poolsAssigned,
    required this.rating,
    this.photoUrl,
    required this.lastActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Worker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Worker(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      companyId: data['companyId'] ?? '',
      status: data['status'] ?? 'available',
      poolsAssigned: data['poolsAssigned'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      photoUrl: data['photoUrl'],
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'companyId': companyId,
      'status': status,
      'poolsAssigned': poolsAssigned,
      'rating': rating,
      'photoUrl': photoUrl,
      'lastActive': Timestamp.fromDate(lastActive),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Worker copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? companyId,
    String? status,
    int? poolsAssigned,
    double? rating,
    String? photoUrl,
    DateTime? lastActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      poolsAssigned: poolsAssigned ?? this.poolsAssigned,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display name for status
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'on_route':
        return 'On Route';
      case 'available':
        return 'Available';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Available';
    }
  }

  // Get last active time as string
  String get lastActiveDisplay {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  String toString() {
    return 'Worker(id: $id, name: $name, email: $email, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Worker && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 