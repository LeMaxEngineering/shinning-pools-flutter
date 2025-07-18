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

  // Create from Firestore document
  factory Worker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Worker document data is null for ID: ${doc.id}');
    }
    
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
      lastActive: _safeDateTime(data['lastActive'], DateTime.now()),
      createdAt: _safeDateTime(data['createdAt'], DateTime.now()),
      updatedAt: _safeDateTime(data['updatedAt'], DateTime.now()),
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