import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import '../../../shared/ui/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    // Listen for authentication state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      if (authService.currentUser != null) {
        _navigateToDashboard();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for authentication state changes
    final authService = context.read<AuthService>();
    if (authService.currentUser != null && mounted) {
      // Use addPostFrameCallback to avoid navigation during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
      _navigateToDashboard();
        }
      });
    }
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    
    try {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      // Handle navigation errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterEmail;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.pleaseEnterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final size = MediaQuery.of(context).size;

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
                // Back button for consistency with RegisterScreen
                Align(
                  alignment: Alignment.topLeft,
                  child: Visibility(
                    visible: false, // Hidden but occupies space
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ),
                const Spacer(),
                // Login form
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 20.0,
                    bottom: 74.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 50),
                      // Welcome text at the same level as form container
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: Text(
                          l10n.welcome,
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showForgotPasswordDialog(context),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
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
                                label: l10n.signIn,
                                isLoading: authService.isLoading,
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await authService.signInWithEmailAndPassword(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    // Check if login was successful and navigate
                                    if (authService.currentUser != null && mounted) {
                                      _navigateToDashboard();
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: l10n.signInWithGoogle,
                                onPressed: authService.isLoading ? null : () async {
                                  await authService.signInWithGoogle();
                                  // Check if login was successful and navigate
                                  if (authService.currentUser != null && mounted) {
                                    _navigateToDashboard();
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(l10n.noAccount),
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

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AuthService>(
            builder: (context, authService, _) => TextButton(
              onPressed: authService.isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        await authService.sendPasswordResetEmail(
                          emailController.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password reset link sent! Check your email.',
                            ),
                          ),
                        );
                      }
                    },
              child: authService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Link'),
            ),
          ),
        ],
      ),
    );
  }
} 