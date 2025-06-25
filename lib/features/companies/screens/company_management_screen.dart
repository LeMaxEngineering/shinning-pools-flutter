import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Companies')),
              const PopupMenuItem(value: 'pending', child: Text('Pending Approval')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'suspended', child: Text('Suspended')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_statusFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _statusFilter == 'All'
            ? FirebaseFirestore.instance.collection('companies').snapshots()
            : FirebaseFirestore.instance
                .collection('companies')
                .where('status', isEqualTo: _statusFilter)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No companies found', style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  Text('Status: $_statusFilter'),
                ],
              ),
            );
          }

          final companies = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              final data = company.data() as Map<String, dynamic>;
              
              return _buildCompanyCard(company.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompanyCard(String companyId, Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Unknown Company',
                      style: AppTextStyles.headline2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['ownerEmail'] ?? 'No email',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (data['address'] != null) ...[
            _buildInfoRow('Address', data['address']),
          ],
          if (data['phone'] != null) ...[
            _buildInfoRow('Phone', data['phone']),
          ],
          if (data['description'] != null) ...[
            _buildInfoRow('Description', data['description']),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              if (status == 'pending') ...[
                Expanded(
                  child: AppButton(
                    label: 'Approve',
                    onPressed: () => _approveCompany(companyId, data),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    onPressed: () => _rejectCompany(companyId),
                    color: Colors.red,
                  ),
                ),
              ] else if (status == 'approved') ...[
                Expanded(
                  child: AppButton(
                    label: 'Suspend',
                    onPressed: () => _suspendCompany(companyId),
                    color: Colors.orange,
                  ),
                ),
              ] else if (status == 'suspended') ...[
                Expanded(
                  child: AppButton(
                    label: 'Reactivate',
                    onPressed: () => _reactivateCompany(companyId),
                    color: Colors.green,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Delete',
                  onPressed: () => _deleteCompany(companyId, data),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'APPROVED';
      case 'pending':
        return 'PENDING';
      case 'suspended':
        return 'SUSPENDED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _approveCompany(String companyId, Map<String, dynamic> data) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update company status
      final companyRef = FirebaseFirestore.instance.collection('companies').doc(companyId);
      batch.update(companyRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user role to admin and set companyId
      final userRef = FirebaseFirestore.instance.collection('users').doc(data['ownerId']);
      batch.update(userRef, {
        'role': 'admin',
        'companyId': companyId,
        'pendingCompanyRequest': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCompany(String companyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company rejected successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _suspendCompany(String companyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company suspended successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error suspending company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateCompany(String companyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'status': 'approved',
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company reactivated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reactivating company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCompany(String companyId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to delete "${data['name']}"? This action cannot be undone and will affect all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Delete company
      final companyRef = FirebaseFirestore.instance.collection('companies').doc(companyId);
      batch.delete(companyRef);

      // Reset user role and remove companyId
      if (data['ownerId'] != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(data['ownerId']);
        batch.update(userRef, {
          'role': 'customer',
          'companyId': null,
          'pendingCompanyRequest': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting company: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 