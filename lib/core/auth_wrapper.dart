import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show splash screen while checking authentication
        if (authService.isLoading) {
          return const SplashScreen();
        }

        // If user is authenticated, navigate to the main dashboard.
        // The DashboardScreen will handle routing to the correct user-specific dashboard,
        // and the CustomerDashboard will handle the invitation blocking UI.
        if (authService.currentUser != null) {
          return const DashboardScreen();
        }

        // If user is not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
} 