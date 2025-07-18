import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../viewmodels/route_viewmodel.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailsScreen({Key? key, required this.routeId}) : super(key: key);

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeViewModel = Provider.of<RouteViewModel>(context);
    final route = routeViewModel.getRouteById(widget.routeId);
    if (route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Route Details')),
        body: const Center(child: Text('Route not found.')),
      );
    }
    if (!_isEditing) {
      _nameController.text = route.routeName;
      _notesController.text = route.notes;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Text('Route Name', style: AppTextStyles.caption),
                _isEditing
                    ? TextField(controller: _nameController)
                    : Text(route.routeName, style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                              Text('Date', style: AppTextStyles.caption),
                Text(routeViewModel.formatDate(route.createdAt)),
                const SizedBox(height: 16),
                Text('Status', style: AppTextStyles.caption),
                Text(route.status),
                const SizedBox(height: 16),
                Text('Notes', style: AppTextStyles.caption),
                _isEditing
                    ? TextField(controller: _notesController, maxLines: 3)
                    : Text(route.notes, style: AppTextStyles.body),
                  const SizedBox(height: 16),
                Text('Pools', style: AppTextStyles.caption),
                ...route.stops.map((stopId) => Text(stopId, style: AppTextStyles.body)),
                const SizedBox(height: 24),
                  Row(
                    children: [
                    if (_isEditing)
                      Expanded(
                        child: AppButton(
                          label: _isLoading ? 'Saving...' : 'Save',
                          onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                final success = await routeViewModel.updateRoute(widget.routeId, {
                                  'routeName': _nameController.text,
                                  'notes': _notesController.text,
                                });
                                setState(() => _isLoading = false);
                                if (success) {
                                  setState(() {
                                    _isEditing = false;
                                    _error = null;
                                  });
                                } else {
                                  setState(() {
                                    _error = routeViewModel.error ?? 'Failed to update route.';
                                  });
                                }
                              },
                          color: AppColors.primary,
                        ),
                      ),
                    if (!_isEditing)
                      Expanded(
                        child: AppButton(
                          label: 'Edit',
                          onPressed: () => setState(() => _isEditing = true),
                              color: AppColors.primary,
                        ),
                      ),
                  ],
                  ),
              ],
              ),
          ),
        ),
      ),
    );
  }
} 