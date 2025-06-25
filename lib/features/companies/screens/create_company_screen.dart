import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  _CreateCompanyScreenState createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: You are not logged in.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final companies = FirebaseFirestore.instance.collection('companies');
      final users = FirebaseFirestore.instance.collection('users');

      // Create company document
      final newCompany = await companies.add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'ownerId': currentUser.id,
        'status': 'pending', // `pending`, `approved`, `rejected`
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user role and add companyId
      await users.doc(currentUser.id).update({
        'role': 'admin',
        'companyId': newCompany.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company created! Please wait for approval.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Sign out to force the app to re-evaluate the user's role and dashboard
      // This is a simple but effective way to handle the role change right now.
      await authService.signOut();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating company: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Company'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Fill out the details below to register your company. Your request will be sent for approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Company Name',
                  controller: _nameController,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a company name' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Address',
                  controller: _addressController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Submit for Approval',
                  onPressed: _createCompany,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 