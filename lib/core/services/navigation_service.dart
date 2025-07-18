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
    try {
      Navigator.of(context).pushNamed('/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToDashboard(BuildContext context, String role) {
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToLogin(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToRegister(BuildContext context) {
    try {
      Navigator.of(context).pushNamed('/register');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToSplash(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void goBack(BuildContext context) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void goBackToRoot(BuildContext context) {
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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