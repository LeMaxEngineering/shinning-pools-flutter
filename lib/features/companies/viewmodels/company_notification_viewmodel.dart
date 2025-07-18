import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';
import '../../users/models/worker_invitation.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/worker_invitation_repository.dart';

class CompanyNotificationViewModel extends ChangeNotifier {
  final WorkerInvitationRepository _invitationRepository;
  final AuthService _authService;

  List<WorkerInvitation> _notifications = [];
  bool _isLoading = false;
  String _error = '';

  CompanyNotificationViewModel({
    required WorkerInvitationRepository invitationRepository,
    required AuthService authService,
  })  : _invitationRepository = invitationRepository,
        _authService = authService;

  List<WorkerInvitation> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get error => _error;

  void initialize() {
    final currentUser = _authService.currentUser;
    if (currentUser?.companyId == null) return;

    _invitationRepository
        .streamRespondedInvitationsForCompany(currentUser!.companyId!)
        .listen((invitations) {
      _notifications = invitations;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load notifications: $e';
      notifyListeners();
    });
  }

  Future<void> markAsSeen(String invitationId) async {
    try {
      await _invitationRepository.markInvitationAsSeen(invitationId);
      // The stream will automatically update the UI
    } catch (e) {
      _error = 'Failed to update notification: $e';
      notifyListeners();
    }
  }
} 