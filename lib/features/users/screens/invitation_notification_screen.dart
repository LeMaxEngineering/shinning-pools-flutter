import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../models/worker_invitation.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/navigation_service.dart';
import 'package:shinning_pools_flutter/core/services/worker_invitation_repository.dart';

class InvitationNotificationScreen extends StatelessWidget {
  final WorkerInvitation invitation;

  const InvitationNotificationScreen({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  Future<String> _fetchCompanyName(String companyId) async {
    final doc = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
        return data['name'];
      }
    }
    return 'Unknown Company';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InvitationViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<String>(
                  future: (invitation.companyName.isEmpty || invitation.companyName == 'Default Company')
                      ? _fetchCompanyName(invitation.companyId)
                      : Future.value(invitation.companyName),
                  builder: (context, snapshot) {
                    final companyName = snapshot.data ?? invitation.companyName;
                    return _buildInvitationCard(context, invitation, viewModel, companyName);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromRGBO(59, 130, 246, 0.8),
            AppColors.primary,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Worker Invitation',
            style: AppTextStyles.headline.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have been invited to join a company as a worker',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, WorkerInvitation invitation, InvitationViewModel viewModel, String companyName) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invited by ${invitation.invitedByUserName}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (invitation.message != null && invitation.message!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.greyLight,
                  ),
                ),
                child: Text(
                  invitation.message!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () => _showRejectDialog(context, invitation, viewModel),
                    label: 'Reject',
                    color: AppColors.error,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    onPressed: () => _acceptInvitation(context, invitation, viewModel),
                    label: 'Accept',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptInvitation(BuildContext context, WorkerInvitation invitation, InvitationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Invitation'),
        content: Text(
          'Are you sure you want to accept the invitation to join ${invitation.companyName}?\n\nYou will be logged out and need to log back in to access your new worker account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              _processInvitationAcceptance(context, invitation, viewModel);
            },
            child: const Text('Accept & Logout'),
          ),
        ],
      ),
    );
  }

  void _processInvitationAcceptance(BuildContext context, WorkerInvitation invitation, InvitationViewModel viewModel) async {
    // Capture services before async operations to avoid context disposal issues
    final invitationRepo = Provider.of<WorkerInvitationRepository>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) {
            Navigator.of(context).pop();
          }
        },
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing invitation...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Step 1: Accept the invitation directly through repository
      await invitationRepo.acceptInvitation(invitation);
      
      // Step 2: Update user role directly through auth service
      await authService.refreshUserData();
      
      // Close loading dialog - check if context is still mounted
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Step 3: Show success dialog with logout suggestion - check if context is still mounted
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                Text('Welcome to ${invitation.companyName}!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have successfully joined ${invitation.companyName} as a worker.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For the best experience with your new worker privileges, we recommend logging out and logging back in.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to worker dashboard
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                },
                child: const Text('Continue as Worker'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  // Logout and redirect to login
                  await authService.signOut();
                  NavigationService.instance.navigateToLogin(context);
                },
                child: const Text('Logout & Login Again'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      // Close loading dialog if still open and context is mounted
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message if context is still mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing invitation: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, WorkerInvitation invitation, InvitationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Invitation'),
        content: Text(
          'Are you sure you want to reject the invitation from ${invitation.companyName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Navigate immediately to dashboard
              Navigator.of(context).pushReplacementNamed('/dashboard');
              
              // Process rejection in background
              viewModel.rejectInvitation(invitation.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
} 