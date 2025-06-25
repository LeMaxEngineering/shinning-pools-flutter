import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'A verification link has been sent to your email address.\nPlease check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('I have verified my email'),
                onPressed: () async {
                  await authService.sendEmailVerification();
                  await authService.reloadUser();
                  if (authService.currentUser?.emailVerified == true) {
                    // Pop this screen if verified
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await authService.sendEmailVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent!')),
                    );
                  }
                },
                child: const Text('Resend verification email'),
              ),
              if (authService.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authService.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 