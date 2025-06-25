import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/worker_viewmodel.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../../../core/services/firebase_auth_repository.dart';
import '../../companies/services/company_service.dart';
import '../../companies/models/company.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/worker_invitation_repository.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';

class AssociatedFormScreen extends StatefulWidget {
  final Map<String, dynamic>? worker;
  
  const AssociatedFormScreen({super.key, this.worker});

  @override
  State<AssociatedFormScreen> createState() => _AssociatedFormScreenState();
}

class _AssociatedFormScreenState extends State<AssociatedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  late WorkerInvitationRepository _invitationRepository;

  bool get _isEditing => widget.worker != null;

  @override
  void initState() {
    super.initState();
    _invitationRepository = WorkerInvitationRepository();
    if (_isEditing) {
      _emailController.text = widget.worker!['email'] ?? '';
      _messageController.text = widget.worker!['message'] ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
        final success = await viewModel.inviteWorker(
          email: _emailController.text.trim(),
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation sent successfully!')),
            );
            Navigator.of(context).pop();
          } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error sending invitation: ${viewModel.error.replaceAll("Exception: ", "")}'),
                backgroundColor: Colors.red,
          ));
        }

          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invite Worker'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Remove Worker'),
                      content: const Text('Are you sure you want to remove this worker from your company? They will revert to customer role.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _removeWorker();
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: Consumer<WorkerViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(59, 130, 246, 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.work_outline,
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
                                    'Invite Worker',
                                    style: AppTextStyles.headline.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send an invitation to join your company as a worker',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Requirements Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Requirements', style: AppTextStyles.subtitle),
                        const SizedBox(height: 16),
                        _buildRequirementItem(
                          Icons.person,
                          'Must have a customer account',
                          'The user must be registered in the system',
                        ),
                        _buildRequirementItem(
                          Icons.pool,
                          'No registered swimming pools',
                          'Users with pools cannot be workers',
                        ),
                        _buildRequirementItem(
                          Icons.email,
                          'Valid email address',
                          'Invitation will be sent to this email',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Invitation Form
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invitation Details', style: AppTextStyles.subtitle),
                        const SizedBox(height: 16),
                        
                        AppTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter the worker\'s email address',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        AppTextField(
                          controller: _messageController,
                          label: 'Personal Message (Optional)',
                          hint: 'Add a personal message to the invitation',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Invitation Process Info
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What happens next?', style: AppTextStyles.subtitle),
                        const SizedBox(height: 16),
                        _buildProcessStep(
                          '1',
                          'Invitation Sent',
                          'The user will receive an invitation notification',
                        ),
                        _buildProcessStep(
                          '2',
                          'User Response',
                          'User can accept or reject the invitation',
                        ),
                        _buildProcessStep(
                          '3',
                          'Role Change',
                          'If accepted, user becomes a worker in your company',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: _isLoading ? 'Sending...' : 'Send Invitation',
                          onPressed: _isLoading ? null : _sendInvitation,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeWorker() async {
    if (widget.worker == null) return;

    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    final success = await viewModel.removeWorkerFromCompany(widget.worker!['id']);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 