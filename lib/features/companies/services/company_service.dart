import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/company.dart';

class CompanyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _error;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, int> getCompanyStats() {
    int pending = 0;
    int approved = 0;
    int suspended = 0;

    for (var company in _companies) {
      switch (company.status) {
        case CompanyStatus.pending:
          pending++;
          break;
        case CompanyStatus.approved:
          approved++;
          break;
        case CompanyStatus.suspended:
          suspended++;
          break;
        default:
          break;
      }
    }

    return {
      'total': _companies.length,
      'pending': pending,
      'approved': approved,
      'suspended': suspended,
    };
  }

  // Load all companies (for root user)
  Future<void> loadCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();

      _companies = querySnapshot.docs
          .map((doc) => Company.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Error loading companies: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error loading companies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load companies by status
  Future<void> loadCompaniesByStatus(String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('companies')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      _companies = querySnapshot.docs
          .map((doc) => Company.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = 'Error loading companies: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error loading companies: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load company by ID
  Future<Company?> loadCompanyById(String companyId) async {
    try {
      final doc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      if (doc.exists) {
        return Company.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Error loading company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error loading company: $e');
      }
      return null;
    }
  }

  // Create new company (for customer registration)
  Future<String?> createCompany({
    required String name,
    required String ownerId,
    required String ownerEmail,
    String? address,
    String? phone,
    String? description,
  }) async {
    try {
      final companyData = {
        'name': name,
        'ownerId': ownerId,
        'ownerEmail': ownerEmail,
        'address': address,
        'phone': phone,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'requestDate': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('companies')
          .add(companyData);

      // Update user to indicate they have a pending company request
      await _firestore
          .collection('users')
          .doc(ownerId)
          .update({
        'pendingCompanyRequest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      _error = 'Error creating company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error creating company: $e');
      }
      return null;
    }
  }

  // Approve company (for root user)
  Future<bool> approveCompany(String companyId) async {
    try {
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      if (!companyDoc.exists) {
        _error = 'Company not found';
        return false;
      }

      final companyData = companyDoc.data()!;
      final ownerId = companyData['ownerId'] as String;

      // Update company status to approved
      await _firestore
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user role to admin and set companyId
      await _firestore
          .collection('users')
          .doc(ownerId)
          .update({
        'role': 'admin',
        'companyId': companyId,
        'pendingCompanyRequest': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload companies list
      await loadCompanies();

      return true;
    } catch (e) {
      _error = 'Error approving company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error approving company: $e');
      }
      return false;
    }
  }

  // Reject company (for root user)
  Future<bool> rejectCompany(String companyId, String reason) async {
    try {
      final companyDoc = await _firestore
          .collection('companies')
          .doc(companyId)
          .get();

      if (!companyDoc.exists) {
        _error = 'Company not found';
        return false;
      }

      final companyData = companyDoc.data()!;
      final ownerId = companyData['ownerId'] as String;

      // Update company status to rejected
      await _firestore
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user to remove pending request
      await _firestore
          .collection('users')
          .doc(ownerId)
          .update({
        'pendingCompanyRequest': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload companies list
      await loadCompanies();

      return true;
    } catch (e) {
      _error = 'Error rejecting company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error rejecting company: $e');
      }
      return false;
    }
  }

  // Suspend company (for root user)
  Future<bool> suspendCompany(String companyId, String reason) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'suspended',
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload companies list
      await loadCompanies();

      return true;
    } catch (e) {
      _error = 'Error suspending company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error suspending company: $e');
      }
      return false;
    }
  }

  // Activate company (for root user)
  Future<bool> activateCompany(String companyId) async {
    try {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
        'suspensionReason': null,
        'suspendedAt': null,
      });

      await loadCompanies();
      return true;
    } catch (e) {
      _error = 'Error activating company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error activating company: $e');
      }
      return false;
    }
  }

  // Delete company (for root user)
  Future<bool> deleteCompany(String companyId) async {
    try {
      // Note: This is a hard delete. Consider a soft delete by setting an 'isDeleted' flag instead.
      // Also consider what to do with associated users, pools, etc. This is a destructive action.
      await _firestore
          .collection('companies')
          .doc(companyId)
          .delete();

      _companies.removeWhere((company) => company.id == companyId);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Error deleting company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error deleting company: $e');
      }
      return false;
    }
  }

  // Get company statistics
  Map<String, int> getCompanyStatistics() {
    final total = _companies.length;
    final active = _companies.where((c) => c.status == CompanyStatus.approved).length;
    final pending = _companies.where((c) => c.status == CompanyStatus.pending).length;
    final suspended = _companies.where((c) => c.status == CompanyStatus.inactive).length;

    return {
      'total': total,
      'active': active,
      'pending': pending,
      'suspended': suspended,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update company (for root user)
  Future<bool> updateCompany({
    required String companyId,
    required String name,
    String? address,
    String? phone,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add optional fields if they are provided
      if (address != null) updateData['address'] = address;
      if (phone != null) updateData['phone'] = phone;
      if (description != null) updateData['description'] = description;

      await _firestore
          .collection('companies')
          .doc(companyId)
          .update(updateData);

      // Reload companies list to reflect changes
      await loadCompanies();

      return true;
    } catch (e) {
      _error = 'Error updating company: $e';
      if (kDebugMode) {
        debugPrint('CompanyService: Error updating company: $e');
      }
      return false;
    }
  }
} 