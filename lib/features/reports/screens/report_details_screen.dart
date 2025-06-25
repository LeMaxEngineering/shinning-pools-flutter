import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  
  const ReportDetailsScreen({super.key, required this.report});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late Map<String, dynamic> _report;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Draft':
        return Colors.grey;
      case 'Pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Daily':
        return Colors.blue;
      case 'Weekly':
        return Colors.green;
      case 'Monthly':
        return Colors.orange;
      case 'Quarterly':
        return Colors.purple;
      case 'Yearly':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'Daily':
        return Icons.today;
      case 'Weekly':
        return Icons.view_week;
      case 'Monthly':
        return Icons.calendar_month;
      case 'Quarterly':
        return Icons.assessment;
      case 'Yearly':
        return Icons.calendar_today;
      default:
        return Icons.description;
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${_report['title']}...')),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${_report['title']}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_report['title']),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: 'Share Report',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getTypeColor(_report['type']),
                        radius: 30,
                        child: Icon(
                          _getReportIcon(_report['type']),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_report['title'], style: AppTextStyles.headline),
                            Text('Type: ${_report['type']}', style: AppTextStyles.caption),
                            Text('Date: ${_report['date']}', style: AppTextStyles.caption),
                            Text('Worker: ${_report['worker']}', style: AppTextStyles.caption),
                            if (_report['route'] != 'N/A')
                              Text('Route: ${_report['route']}', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_report['status']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _report['status'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Key Metrics
            if (_report['poolsCompleted'] > 0) ...[
              Text('Key Metrics', style: AppTextStyles.headline),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text(
                            '${_report['poolsCompleted']}/${_report['totalPools']}',
                            style: AppTextStyles.headline.copyWith(color: AppColors.primary),
                          ),
                          Text('Pools Completed', style: AppTextStyles.caption),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _report['totalPools'] > 0 
                                ? _report['poolsCompleted'] / _report['totalPools'] 
                                : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text(
                            '${_report['hoursWorked']}h',
                            style: AppTextStyles.headline.copyWith(color: Colors.blue),
                          ),
                          Text('Hours Worked', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Text(
                            '${_report['issues']}',
                            style: AppTextStyles.headline.copyWith(color: Colors.orange),
                          ),
                          Text('Issues Found', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],

            // Performance Summary
            Text('Performance Summary', style: AppTextStyles.headline),
            const SizedBox(height: 16),
            
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Efficiency Metrics', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  
                  if (_report['poolsCompleted'] > 0) ...[
                    _buildMetricRow('Completion Rate', '${((_report['poolsCompleted'] / _report['totalPools']) * 100).toStringAsFixed(1)}%'),
                    _buildMetricRow('Average Time per Pool', '${(_report['hoursWorked'] / _report['poolsCompleted']).toStringAsFixed(1)} hours'),
                    _buildMetricRow('Issues per Pool', '${(_report['issues'] / _report['poolsCompleted']).toStringAsFixed(2)}'),
                  ] else ...[
                    _buildMetricRow('Status', _report['status']),
                    _buildMetricRow('Notes', _report['notes'] ?? 'No notes available'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section
            Text('Notes & Comments', style: AppTextStyles.headline),
            const SizedBox(height: 16),
            
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Report Notes', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  Text(
                    _report['notes'] ?? 'No notes available for this report.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recommendations (if applicable)
            if (_report['issues'] > 0) ...[
              Text('Recommendations', style: AppTextStyles.headline),
              const SizedBox(height: 16),
              
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action Items', style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    
                    if (_report['type'] == 'Daily' && _report['issues'] > 0)
                      _buildRecommendationItem(
                        'Follow up on reported issues',
                        'Address the ${_report['issues']} issues found during today\'s work',
                        Icons.warning,
                        Colors.orange,
                      ),
                    
                    if (_report['type'] == 'Weekly' && _report['poolsCompleted'] < _report['totalPools'])
                      _buildRecommendationItem(
                        'Improve completion rate',
                        'Focus on completing all scheduled pools to meet weekly targets',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    
                    if (_report['type'] == 'Monthly')
                      _buildRecommendationItem(
                        'Equipment maintenance',
                        'Schedule equipment inspection and maintenance for next month',
                        Icons.build,
                        Colors.green,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Export PDF',
                    onPressed: _exportReport,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Share Report',
                    onPressed: _shareReport,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 