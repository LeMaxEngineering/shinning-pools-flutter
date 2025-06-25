import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String companyId;
  final String serviceType;
  final String status;
  final Map<String, dynamic> billingInfo;
  final List<Map<String, dynamic>> serviceHistory;
  final Map<String, dynamic> preferences;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.companyId,
    required this.serviceType,
    required this.status,
    required this.billingInfo,
    required this.serviceHistory,
    required this.preferences,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      companyId: data['companyId'] ?? '',
      serviceType: data['serviceType'] ?? 'standard',
      status: data['status'] ?? 'active',
      billingInfo: Map<String, dynamic>.from(data['billingInfo'] ?? {}),
      serviceHistory: List<Map<String, dynamic>>.from(data['serviceHistory'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      notes: data['notes'] ?? '',
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
      'address': address,
      'companyId': companyId,
      'serviceType': serviceType,
      'status': status,
      'billingInfo': billingInfo,
      'serviceHistory': serviceHistory,
      'preferences': preferences,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? companyId,
    String? serviceType,
    String? status,
    Map<String, dynamic>? billingInfo,
    List<Map<String, dynamic>>? serviceHistory,
    Map<String, dynamic>? preferences,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      companyId: companyId ?? this.companyId,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      billingInfo: billingInfo ?? this.billingInfo,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      preferences: preferences ?? this.preferences,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display name for service type
  String get serviceTypeDisplay {
    switch (serviceType.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'standard':
        return 'Standard';
      default:
        return 'Standard';
    }
  }

  // Get display name for status
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return 'Active';
    }
  }

  // Get pools count from service history
  int get poolsCount {
    // This would be calculated from actual pool data
    // For now, return a placeholder
    return serviceHistory.length;
  }

  // Get last service date
  String get lastService {
    if (serviceHistory.isEmpty) {
      return 'Never';
    }
    
    final lastService = serviceHistory.last;
    final date = lastService['date'] as Timestamp?;
    if (date == null) {
      return 'Unknown';
    }
    
    final now = DateTime.now();
    final serviceDate = date.toDate();
    final difference = now.difference(serviceDate);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    } else {
      return '${(difference.inDays / 30).round()} months ago';
    }
  }

  // Get next service date
  String get nextService {
    // This would be calculated from scheduling data
    // For now, return a placeholder
    return 'Not scheduled';
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 