import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/worker_invitation_repository.dart';
import '../../../core/services/auth_service.dart';
import '../models/worker_invitation.dart';

class InvitationViewModel extends ChangeNotifier {
  final WorkerInvitationRepository _invitationRepository;
  final AuthService _authService;

  List<WorkerInvitation> _invitations = [];
  List<WorkerInvitation> _pendingInvitations = [];
  bool _isLoading = false;
  String _error = '';
  bool _isInitialized = false;

  InvitationViewModel({
    required WorkerInvitationRepository invitationRepository,
    required AuthService authService,
  }) : _invitationRepository = invitationRepository,
       _authService = authService;

  // Getters
  List<WorkerInvitation> get invitations => _invitations;
  List<WorkerInvitation> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInitialized => _isInitialized;
  bool get hasPendingInvitations => _pendingInvitations.isNotEmpty;

  // Initialize the view model
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return;
      }

      // Load invitations for the current user
      await loadInvitations();
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize: $e');
      _setLoading(false);
    }
  }

  // Load invitations for the current user
  Future<void> loadInvitations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Stream invitations for the current user
      _invitationRepository.streamUserInvitations(currentUser.id).listen(
        (invitations) {
          // Use post-frame callback to prevent setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _invitations = invitations;
            _pendingInvitations = invitations.where((inv) => inv.status == InvitationStatus.pending).toList();
            notifyListeners();
          });
        },
        onError: (error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setError('Failed to load invitations: $error');
          });
        },
      );
    } catch (e) {
      _setError('Failed to load invitations: $e');
    }
  }

  // Accept an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      // Fetch the invitation directly to ensure we have the latest data
      final invitation = await _invitationRepository.getInvitation(invitationId);
      await _invitationRepository.acceptInvitation(invitation);
      
      // Refresh user data to get updated role
      await _authService.refreshUserData();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to accept invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reject an invitation
  Future<bool> rejectInvitation(String invitationId) async {
    try {
      _setLoading(true);
      _setError('');

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      // Fetch the invitation directly to ensure we have the latest data
      final invitation = await _invitationRepository.getInvitation(invitationId);
      await _invitationRepository.rejectInvitation(invitation);
      
      // Manually update local state for immediate UI response
      _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to reject invitation: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get invitation by ID
  WorkerInvitation? getInvitationById(String id) {
    try {
      return _pendingInvitations.firstWhere((invitation) => invitation.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if user has any pending invitations
  Future<bool> checkForPendingInvitations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      return await _invitationRepository.hasPendingInvitations(currentUser.id);
    } catch (e) {
      return false;
    }
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

  // Refresh invitations
  Future<void> refresh() async {
    await loadInvitations();
  }

  // Reset state when user logs out
  void reset() {
    _pendingInvitations = [];
    _isLoading = false;
    _error = '';
    _isInitialized = false;
    notifyListeners();
  }
} 