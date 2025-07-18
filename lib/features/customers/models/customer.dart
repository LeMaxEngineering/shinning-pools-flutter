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
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedUserId;

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
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.linkedUserId,
  });

  // Create from Firestore document
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null) {
      throw Exception('Customer.fromFirestore: Document data is null for id: ${doc.id}');
    }
    final data = rawData as Map<String, dynamic>;
    try {
      return Customer(
        id: doc.id,
        name: _safeString(data['name'], ''),
        email: _safeString(data['email'], ''),
        phone: _safeString(data['phone'], ''),
        address: _safeString(data['address'], ''),
        companyId: _safeString(data['companyId'], ''),
        serviceType: _safeString(data['serviceType'], 'standard'),
        status: _safeString(data['status'], 'active'),
        billingInfo: Map<String, dynamic>.from(data['billingInfo'] ?? {}),
        serviceHistory: List<Map<String, dynamic>>.from(data['serviceHistory'] ?? []),
        preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
        notes: _safeString(data['notes'], ''),
        photoUrl: data['photoUrl'] as String?,
        createdAt: _safeDateTime(data['createdAt'], DateTime.now()),
        updatedAt: _safeDateTime(data['updatedAt'], DateTime.now()),
        linkedUserId: data['linkedUserId'] as String?,
      );
    } catch (e) {
      print('Error creating Customer from Firestore data: $e');
      print('Problematic data: $data');
      rethrow;
    }
  }

  // Helper method to safely convert values to strings
  static String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Timestamp) {
      print('Warning: Found Timestamp where String expected: $value');
      return value.toDate().toString();
    }
    return value.toString();
  }

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
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (linkedUserId != null) 'linkedUserId': linkedUserId,
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
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedUserId,
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
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedUserId: linkedUserId ?? this.linkedUserId,
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
    final dateValue = lastService['date'];
    if (dateValue == null) {
      return 'Unknown';
    }
    
    DateTime? serviceDate;
    if (dateValue is Timestamp) {
      serviceDate = dateValue.toDate();
    } else if (dateValue is String) {
      try {
        serviceDate = DateTime.parse(dateValue);
      } catch (e) {
        return 'Unknown';
      }
    } else if (dateValue is DateTime) {
      serviceDate = dateValue;
    } else {
      return 'Unknown';
    }
    
    if (serviceDate == null) {
      return 'Unknown';
    }
    
    final now = DateTime.now();
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