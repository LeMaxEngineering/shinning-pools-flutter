import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker.dart';
import '../../../core/services/worker_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/worker_invitation_repository.dart';
import '../models/worker_invitation.dart';
import '../../companies/models/company.dart';

class WorkerViewModel extends ChangeNotifier {
  final WorkerRepository _workerRepository;
  final AuthService _authService;
  final WorkerInvitationRepository _invitationRepository;

  WorkerViewModel({
    required WorkerRepository workerRepository,
    required AuthService authService,
    WorkerInvitationRepository? invitationRepository,
  }) : _workerRepository = workerRepository,
       _authService = authService,
       _invitationRepository =
           invitationRepository ?? WorkerInvitationRepository();

  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<WorkerInvitation> _invitations = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Getters
  List<Worker> get workers => _workers;
  List<Worker> get filteredWorkers => _filteredWorkers;
  List<WorkerInvitation> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // Statistics
  int get totalWorkers => _workers.length;
  int get activeWorkers =>
      _workers.where((w) => w.status.toLowerCase() == 'active').length;
  int get onRouteWorkers =>
      _workers.where((w) => w.status.toLowerCase() == 'on_route').length;
  int get availableWorkers =>
      _workers.where((w) => w.status.toLowerCase() == 'available').length;
  int get pendingInvitations =>
      _invitations.where((i) => i.status == InvitationStatus.pending).length;

  // Initialize and load workers
  Future<void> initialize() async {
    await Future.wait([loadWorkers(), loadInvitations()]);
  }

  // Load workers for the current company
  Future<void> loadWorkers() async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return;
      }

      // Get company ID from user
      String companyId;
      if (currentUser.role.isRoot) {
        // Root user can see all workers (for now, we'll use a placeholder)
        companyId = 'all';
      } else {
        companyId = currentUser.companyId ?? '';
      }

      if (companyId.isEmpty && !currentUser.role.isRoot) {
        _setError('Company ID not found');
        return;
      }

      // Stream workers
      _workerRepository
          .streamCompanyWorkers(companyId)
          .listen(
            (workers) {
              // Use post-frame callback to prevent setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _workers = workers;
                _applyFilters();
                _setLoading(false);
              });
            },
            onError: (error) {
              // Use post-frame callback to prevent setState during build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _setError('Failed to load workers: $error');
                _setLoading(false);
              });
            },
          );
    } catch (e) {
      _setError('Failed to load workers: $e');
      _setLoading(false);
    }
  }

  // Load invitations for the current company
  Future<void> loadInvitations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final invitations = await _invitationRepository.getCompanyInvitations(
        currentUser.companyId!,
      );
      _invitations = invitations;
      notifyListeners();
    } catch (error) {
      _error = 'Failed to load invitations: $error';
      notifyListeners();
    }
  }

  // Invite a new worker by email
  Future<bool> inviteWorker({required String email, String? message}) async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      String companyId;
      if (currentUser.role.isRoot) {
        // For root user, we need to determine which company to assign to
        companyId = 'default_company';
      } else {
        companyId = currentUser.companyId ?? '';
      }

      if (companyId.isEmpty) {
        _setError('Company ID not found');
        return false;
      }

      // Fetch the real company name from Firestore
      String companyName = '';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null &&
              data['name'] != null &&
              data['name'].toString().trim().isNotEmpty) {
            companyName = data['name'];
          }
        }
      } catch (e) {
        // fallback to currentUser.companyName or default if fetch fails
        companyName = currentUser.companyName ?? 'Default Company';
      }
      if (companyName.isEmpty) {
        companyName = currentUser.companyName ?? 'Default Company';
      }

      // Check if email is already invited
      final alreadyInvited = await _invitationRepository.isEmailAlreadyInvited(
        email,
        companyId,
      );
      if (alreadyInvited) {
        _setError('This email has already been invited to join your company');
        return false;
      }

      // Find user by email
      final userDoc = await _invitationRepository.findUserByEmail(email);
      if (userDoc == null) {
        _setError(
          'Email not registered. The user must have an account to be invited.',
        );
        return false;
      }

      final invitedUserId = userDoc.id;

      // Validate user eligibility for worker invitation
      final validation = await _invitationRepository
          .validateUserForWorkerInvitation(invitedUserId);
      if (!validation['isValid']) {
        _setError(validation['error']);
        return false;
      }

      // Create invitation
      await _invitationRepository.createInvitation(
        companyId: companyId,
        companyName: companyName,
        invitedUserEmail: email,
        invitedByUserId: currentUser.id,
        invitedByUserName: currentUser.name,
        message: message,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to invite worker: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update worker
  Future<bool> updateWorker(String workerId, Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError('');

      await _workerRepository.updateWorker(workerId, data);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update worker: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete worker
  Future<bool> deleteWorker(String workerId) async {
    try {
      _setLoading(true);
      _setError('');

      await _workerRepository.deleteWorker(workerId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete worker: $e');
      _setLoading(false);
      return false;
    }
  }

  // Cancel invitation
  Future<bool> cancelInvitation(String invitationId) async {
    try {
      _setLoading(true);
      _setError('');

      await _invitationRepository.deleteInvitation(invitationId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to cancel invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Update status filter
  void updateStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilters();
  }

  // Apply filters to workers
  void _applyFilters() {
    _filteredWorkers = _workers.where((worker) {
      final matchesSearch =
          worker.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          worker.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _statusFilter == 'All' || worker.statusDisplay == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Get worker by ID
  Worker? getWorkerById(String id) {
    try {
      return _workers.firstWhere((worker) => worker.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get invitation by ID
  WorkerInvitation? getInvitationById(String id) {
    try {
      return _invitations.firstWhere((invitation) => invitation.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh workers and invitations
  Future<void> refresh() async {
    await Future.wait([loadWorkers(), loadInvitations()]);
  }

  // Remove worker from company (revert to customer)
  Future<bool> removeWorkerFromCompany(String workerId) async {
    try {
      _setLoading(true);
      _setError('');

      await _invitationRepository.removeWorkerFromCompany(workerId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove worker: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update assignees list with both workers and admins
  void updateAssignees(List<Map<String, dynamic>> assignees) {
    _workers = assignees
        .map(
          (assignee) => Worker(
            id: assignee['id'],
            name: assignee['name'],
            email: assignee['email'] ?? '',
            phone: assignee['phone'] ?? '',
            companyId: assignee['companyId'] ?? '',
            status: assignee['status'] ?? 'active',
            poolsAssigned: assignee['poolsAssigned'] ?? 0,
            rating: (assignee['rating'] ?? 0.0).toDouble(),
            lastActive: assignee['lastActive'] != null
                ? (assignee['lastActive'] is Timestamp
                      ? assignee['lastActive'].toDate()
                      : DateTime.parse(assignee['lastActive'].toString()))
                : DateTime.now(),
            createdAt: assignee['createdAt'] != null
                ? (assignee['createdAt'] is Timestamp
                      ? assignee['createdAt'].toDate()
                      : DateTime.parse(assignee['createdAt'].toString()))
                : DateTime.now(),
            updatedAt: assignee['updatedAt'] != null
                ? (assignee['updatedAt'] is Timestamp
                      ? assignee['updatedAt'].toDate()
                      : DateTime.parse(assignee['updatedAt'].toString()))
                : DateTime.now(),
          ),
        )
        .toList();

    _applyFilters();
    notifyListeners();
  }
}
