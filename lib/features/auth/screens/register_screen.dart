import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/colors.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_button.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_text_field.dart';
import 'package:shinning_pools_flutter/l10n/l10n.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final size = MediaQuery.of(context).size;

    // If registration was successful and we have a user, pop back to login
    if (authService.currentUser != null && !authService.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/img/splash02.png',
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
          ),
          // Dark overlay
          Container(
            width: size.width,
            height: size.height,
            color: const Color.fromRGBO(0, 0, 0, 0.4),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                // Register form
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 50.0,
                    bottom: 74.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: Text(
                          'Create Account',
                          style: AppTextStyles.headline.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Form container
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                label: l10n.email,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                enabled: !authService.isLoading,
                                sanitizationType: 'email',
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: l10n.password,
                                controller: _passwordController,
                                obscureText: true,
                                validator: _validatePassword,
                                enabled: !authService.isLoading,
                                sanitizationType: 'text',
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Confirm Password',
                                controller: _confirmPasswordController,
                                obscureText: true,
                                validator: _validateConfirmPassword,
                                enabled: !authService.isLoading,
                                sanitizationType: 'text',
                              ),
                              const SizedBox(height: 24),
                              if (authService.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    authService.error!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              AppButton(
                                label: 'Register',
                                isLoading: authService.isLoading,
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    authService.registerWithEmailAndPassword(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Already have an account? Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 