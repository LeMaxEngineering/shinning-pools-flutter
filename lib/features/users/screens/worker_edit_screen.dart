import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../viewmodels/worker_viewmodel.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class WorkerEditScreen extends StatefulWidget {
  final Worker worker;
  const WorkerEditScreen({super.key, required this.worker});

  @override
  State<WorkerEditScreen> createState() => _WorkerEditScreenState();
}

class _WorkerEditScreenState extends State<WorkerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _phoneController = TextEditingController(text: widget.worker.phone);
    _emailController = TextEditingController(text: widget.worker.email);
    _status = widget.worker.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    final success = await viewModel.updateWorker(
      widget.worker.id,
      {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': _status,
      },
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Worker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Name',
                validator: (value) => value == null || value.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                enabled: false,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Phone required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'on_route', child: Text('On Route')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isLoading ? 'Saving...' : 'Save',
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 