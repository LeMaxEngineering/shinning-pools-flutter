import 'package:flutter/material.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> route;
  
  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late Map<String, dynamic> _route;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _route = Map<String, dynamic>.from(widget.route);
    _notesController.text = _route['notes'] ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.grey;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updatePoolStatus(int poolIndex, String newStatus) {
    setState(() {
      _route['pools'][poolIndex]['status'] = newStatus;
      
      // Update completed pools count
      _route['completedPools'] = _route['pools']
          .where((pool) => pool['status'] == 'Completed')
          .length;
      
      // Update route status based on pool statuses
      if (_route['completedPools'] == _route['totalPools']) {
        _route['status'] = 'Completed';
      } else if (_route['pools'].any((pool) => pool['status'] == 'In Progress')) {
        _route['status'] = 'In Progress';
      }
    });
  }

  void _addPoolNote(int poolIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final noteController = TextEditingController(
          text: _route['pools'][poolIndex]['notes'] ?? '',
        );
        
        return AlertDialog(
          title: Text('Add Note for ${_route['pools'][poolIndex]['name']}'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: 'Enter notes about this pool...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _route['pools'][poolIndex]['notes'] = noteController.text;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note added successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveRouteNotes() {
    setState(() {
      _route['notes'] = _notesController.text;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route notes saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_route['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRouteNotes,
            tooltip: 'Save Notes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Overview Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.route, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_route['name'], style: AppTextStyles.headline),
                            Text('Date: ${_route['date']}', style: AppTextStyles.caption),
                            Text('Worker: ${_route['worker']}', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_route['status']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _route['status'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Progress', style: AppTextStyles.subtitle),
                          Text(
                            '${_route['completedPools']}/${_route['totalPools']} pools completed',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _route['totalPools'] > 0 
                            ? _route['completedPools'] / _route['totalPools'] 
                            : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(_route['status']),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Duration Information
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated Duration', style: AppTextStyles.caption),
                            Text(_route['estimatedDuration'], style: AppTextStyles.subtitle),
                          ],
                        ),
                      ),
                      if (_route['actualDuration'] != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Actual Duration', style: AppTextStyles.caption),
                              Text(_route['actualDuration'], style: AppTextStyles.subtitle),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Route Notes
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route Notes', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Add notes about this route...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Save Notes',
                    onPressed: _saveRouteNotes,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pools List
            Text('Pools in Route', style: AppTextStyles.headline),
            const SizedBox(height: 16),
            
            ..._route['pools'].asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final pool = entry.value;
              
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(pool['status']),
                        child: const Icon(Icons.pool, color: Colors.white),
                      ),
                      title: Text(pool['name'], style: AppTextStyles.subtitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scheduled: ${pool['time']}'),
                          if (pool['notes'] != null && pool['notes'].isNotEmpty)
                            Text('Notes: ${pool['notes']}', style: AppTextStyles.caption),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(pool['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pool['status'],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pool Actions
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Add Note',
                            onPressed: () => _addPoolNote(index),
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: pool['status'],
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Pending', 'In Progress', 'Completed', 'Delayed']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updatePoolStatus(index, value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // Route Actions
            if (_route['status'] == 'Scheduled')
              AppButton(
                label: 'Start Route',
                onPressed: () {
                  setState(() {
                    _route['status'] = 'In Progress';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route started!')),
                  );
                },
                color: Colors.green,
              ),
            
            if (_route['status'] == 'In Progress')
              AppButton(
                label: 'Complete Route',
                onPressed: () {
                  setState(() {
                    _route['status'] = 'Completed';
                    _route['actualDuration'] = '3 hours 15 min';
                    for (var pool in _route['pools']) {
                      pool['status'] = 'Completed';
                    }
                    _route['completedPools'] = _route['totalPools'];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route completed!')),
                  );
                },
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }
} 