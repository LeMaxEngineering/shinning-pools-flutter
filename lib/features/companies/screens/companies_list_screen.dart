import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../services/company_service.dart';
import '../models/company.dart';
import 'create_company_screen.dart';
import 'company_edit_screen.dart';

class CompaniesListScreen extends StatefulWidget {
  const CompaniesListScreen({super.key});

  @override
  State<CompaniesListScreen> createState() => _CompaniesListScreenState();
}

class _CompaniesListScreenState extends State<CompaniesListScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rejectionReasonController = TextEditingController();
  final TextEditingController _suspensionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyService>().loadCompanies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rejectionReasonController.dispose();
    _suspensionReasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat.yMd().format(date);
  }

  List<Company> get _filteredCompanies {
    final companyService = context.watch<CompanyService>();
    return companyService.companies.where((company) {
      final matchesSearch = company.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          company.ownerEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (company.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesStatus = _statusFilter == 'All' || company.status.name == _statusFilter.toLowerCase();
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildStatsHeader(CompanyService companyService) {
    final stats = companyService.getCompanyStats();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatButton(
                context, 'Pending', stats['pending'].toString(), Colors.orange, 'Pending'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatButton(
                context, 'Approved', stats['approved'].toString(), Colors.green, 'Approved'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatButton(context, 'Suspended', stats['suspended'].toString(),
                Colors.red, 'Suspended'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatButton(context, 'Total', stats['total'].toString(),
                AppColors.primary, 'All'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton(BuildContext context, String title, String count,
      Color color, String filter) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 50),
      ),
      onPressed: () {
        setState(() {
          _statusFilter = filter;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: AppTextStyles.headline
                .copyWith(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CompanyStatus status) {
    switch (status) {
      case CompanyStatus.approved:
        return Colors.green;
      case CompanyStatus.pending:
        return Colors.orange;
      case CompanyStatus.suspended:
        return Colors.red;
      case CompanyStatus.rejected:
        return Colors.red;
      case CompanyStatus.inactive:
        return Colors.grey;
    }
  }

  void _addNewCompany() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company created successfully!')),
      );
      context.read<CompanyService>().loadCompanies();
    }
  }

  void _editCompany(Company company) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CompanyEditScreen(company: company)),
    );
    
    // If the edit was successful (result is true), refresh the companies list
    if (result == true) {
      context.read<CompanyService>().loadCompanies();
    }
  }

  void _viewCompanyDetails(Company company) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Company Details: ${company.name}'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text('Owner Email: ${company.ownerEmail}'),
                if (company.address != null) Text('Address: ${company.address}'),
                if (company.phone != null) Text('Phone: ${company.phone}'),
                if (company.description != null) Text('Description: ${company.description}'),
                Text('Status: ${company.statusDisplayName}'),
                Text('Request Date: ${_formatDate(company.requestDate)}'),
                if (company.approvedAt != null) Text('Approved: ${_formatDate(company.approvedAt!)}'),
                if (company.rejectedAt != null) Text('Rejected: ${_formatDate(company.rejectedAt!)}'),
                if (company.suspendedAt != null) Text('Suspended: ${_formatDate(company.suspendedAt!)}'),
                if (company.rejectionReason != null) Text('Rejection Reason: ${company.rejectionReason}'),
                if (company.suspensionReason != null) Text('Suspension Reason: ${company.suspensionReason}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _approveCompany(Company company) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Company'),
          content: Text('Are you sure you want to approve ${company.name}? This will grant them admin access.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final companyService = context.read<CompanyService>();
                final success = await companyService.approveCompany(company.id);
                
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${company.name} has been approved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error approving company: ${companyService.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  void _rejectCompany(Company company) {
    _rejectionReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to reject ${company.name}?'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _rejectionReasonController,
                label: 'Rejection Reason',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for rejection';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_rejectionReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rejection reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                final companyService = context.read<CompanyService>();
                final success = await companyService.rejectCompany(
                  company.id, 
                  _rejectionReasonController.text.trim()
                );
                
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${company.name} has been rejected.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error rejecting company: ${companyService.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _suspendCompany(Company company) {
    _suspensionReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suspend Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Are you sure you want to suspend ${company.name}? This will disable their account access.'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _suspensionReasonController,
                label: 'Reason for Suspension',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason for suspension';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_suspensionReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a suspension reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                final companyService = context.read<CompanyService>();
                final success = await companyService.suspendCompany(
                    company.id, _suspensionReasonController.text.trim());

                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${company.name} has been suspended.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Error suspending company: ${companyService.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Suspend'),
            ),
          ],
        );
      },
    );
  }

  void _activateCompany(Company company) {
    // TODO: Implement activate company logic in service
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Activate Company'),
          content: Text(
              'Are you sure you want to activate ${company.name}? This will restore their account access.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Activate ${company.name} coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Activate'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCompany(Company company) {
    // TODO: Implement delete company logic in service
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Company'),
          content: Text(
              'Are you sure you want to permanently delete ${company.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Delete ${company.name} coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyService = context.watch<CompanyService>();
    final filteredCompanies = _filteredCompanies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: _addNewCompany,
            tooltip: 'Add New Company',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(companyService),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    label: 'Search by name, email...',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  dropdownColor: AppColors.primary,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  value: _statusFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      _statusFilter = newValue!;
                    });
                  },
                  items: <String>[
                    'All',
                    'Pending',
                    'Approved',
                    'Suspended',
                    'Rejected'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (companyService.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (companyService.error != null)
            Expanded(
              child: Center(
                child: AppCard(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading companies: ${companyService.error}',
                          style: AppTextStyles.body.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Retry',
                          onPressed: () => companyService.loadCompanies(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (filteredCompanies.isEmpty)
            const Expanded(
              child: Center(
                        child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No companies found matching your criteria.'),
                          ),
                        ),
                      ),
            )
          else
                      Expanded(
                        child: AppCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                                const Color.fromRGBO(59, 130, 246, 0.1)),
                            columns: const [
                              DataColumn(
                                  label: Text('Company',
                                      style: AppTextStyles.subtitle)),
                              DataColumn(
                                  label: Text('Status',
                                      style: AppTextStyles.subtitle)),
                              DataColumn(
                                  label: Text('Registered',
                                      style: AppTextStyles.subtitle)),
                              DataColumn(
                                  label:
                                      Text('Actions', style: AppTextStyles.subtitle)),
                            ],
                            rows: filteredCompanies
                                .map((company) => _buildDataRow(context, company))
                                .toList(),
                          ),
                        ),
                      ),
                    );
                  }
                          ),
                        ),
                      ),
                    ],
                  ),
    );
  }

  DataRow _buildDataRow(BuildContext context, Company company) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
              Text(company.name, style: AppTextStyles.body),
              Text(company.ownerEmail, style: AppTextStyles.caption),
            ],
          ),
        ),
        DataCell(
          Chip(
            label: Text(
              company.statusDisplayName,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
            backgroundColor: _getStatusColor(company.status),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        DataCell(Text(_formatDate(company.createdAt))),
        DataCell(_buildActionsPopup(company)),
      ],
    );
  }

  Widget _buildActionsPopup(Company company) {
    final List<PopupMenuEntry<String>> items = [];

    items.add(
        const PopupMenuItem(value: 'view', child: Text('View Details')));

    switch (company.status) {
      case CompanyStatus.pending:
        items.add(const PopupMenuItem(value: 'approve', child: Text('Approve')));
        items.add(const PopupMenuItem(value: 'reject', child: Text('Reject')));
        break;
      case CompanyStatus.approved:
        items.add(const PopupMenuItem(value: 'suspend', child: Text('Suspend')));
        break;
      case CompanyStatus.suspended:
        items.add(
            const PopupMenuItem(value: 'activate', child: Text('Activate')));
        break;
      case CompanyStatus.rejected:
        // No actions for rejected
        break;
      case CompanyStatus.inactive:
        // No actions for inactive
        break;
    }

    items.add(const PopupMenuDivider());
    items.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
    items.add(const PopupMenuItem(
        value: 'delete',
        child: Text('Delete', style: TextStyle(color: Colors.red))));

    return PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        _viewCompanyDetails(company);
                                        break;
          case 'approve':
            _approveCompany(company);
            break;
          case 'reject':
            _rejectCompany(company);
            break;
          case 'suspend':
            _suspendCompany(company);
            break;
          case 'activate':
            _activateCompany(company);
                                        break;
                                      case 'edit':
                                        _editCompany(company);
                                        break;
                                      case 'delete':
                                        _deleteCompany(company);
                                        break;
                                    }
                                  },
      itemBuilder: (context) => items,
      icon: const Icon(Icons.more_vert),
    );
  }
} 