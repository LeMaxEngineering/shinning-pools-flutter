import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class NavigationService extends ChangeNotifier {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();

  NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Navigation methods
  void navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  void navigateToDashboard(BuildContext context, String role) {
    switch (role) {
      case 'root':
        Navigator.of(context).pushReplacementNamed('/rootDashboard');
        break;
      case 'admin':
      case 'worker':
      case 'customer':
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed('/register');
  }

  void navigateToSplash(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void goBackToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Role-based navigation helpers
  bool canAccessRootFeatures(String role) {
    return role == 'root';
  }

  bool canAccessAdminFeatures(String role) {
    return role == 'root' || role == 'admin';
  }

  bool canAccessWorkerFeatures(String role) {
    return role == 'root' || role == 'admin' || role == 'worker';
  }

  // Navigation state management
  void handleAuthStateChange(BuildContext context, bool isAuthenticated, String? role) {
    if (isAuthenticated && role != null) {
      navigateToDashboard(context, role);
    } else {
      navigateToLogin(context);
    }
  }
} 