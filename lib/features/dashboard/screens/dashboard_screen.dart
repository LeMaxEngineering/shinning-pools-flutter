import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/core/services/user.dart';
import 'package:shinning_pools_flutter/core/services/role.dart';
import '../../users/screens/profile_screen.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'root_dashboard.dart';
import 'company_dashboard.dart';
import 'associated_dashboard.dart';
import 'customer_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final currentUser = authService.currentUser;
        
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Widget targetDashboard;

        switch (currentUser.role) {
          case UserRole.root:
            targetDashboard = const RootDashboard();
            break;
          case UserRole.admin:
            targetDashboard = const CompanyDashboard();
            break;
          case UserRole.worker:
            targetDashboard = const AssociatedDashboard();
            break;
          case UserRole.customer:
            targetDashboard = const CustomerDashboard();
            break;
          default:
            targetDashboard = const RootDashboard();
        }

        return targetDashboard;
      },
    );
  }
} 