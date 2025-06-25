import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shinning_pools_flutter/core/auth_wrapper.dart';
import 'package:shinning_pools_flutter/features/auth/screens/login_screen.dart';
import 'package:shinning_pools_flutter/features/auth/screens/register_screen.dart';
import 'package:shinning_pools_flutter/features/companies/screens/companies_list_screen.dart';
import 'package:shinning_pools_flutter/features/companies/screens/create_company_screen.dart';
import 'package:shinning_pools_flutter/features/companies/screens/company_registration_screen.dart';
import 'package:shinning_pools_flutter/features/companies/screens/company_management_screen.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customer_form_screen.dart';
import 'package:shinning_pools_flutter/features/customers/screens/customers_list_screen.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/associated_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/company_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/customer_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/dashboard_screen.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/root_dashboard.dart';
import 'package:shinning_pools_flutter/features/pools/screens/maintenance_form_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pool_details_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pool_form_screen.dart';
import 'package:shinning_pools_flutter/features/pools/screens/pools_list_screen.dart';
import 'package:shinning_pools_flutter/features/reports/screens/report_details_screen.dart';
import 'package:shinning_pools_flutter/features/reports/screens/reports_list_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/route_details_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/routes_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_form_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/profile_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/user_management_screen.dart';
import 'package:shinning_pools_flutter/l10n/l10n.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/app_theme.dart';
import 'package:shinning_pools_flutter/shared/ui/widgets/app_background.dart';

class ShinningPoolsApp extends StatelessWidget {
  const ShinningPoolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pool Management',
      theme: appTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const AuthWrapper(),
      routes: {
        // Auth Routes
        '/login': (context) => const LoginScreen(),
        
        // Dashboard Routes
        '/rootDashboard': (context) => const RootDashboard(),
        '/dashboard': (context) => const DashboardScreen(),
        '/companyDashboard': (context) => const CompanyDashboard(),
        '/associatedDashboard': (context) => const AssociatedDashboard(),
        '/customerDashboard': (context) => const CustomerDashboard(),
        '/unknownRole': (context) => const DashboardScreen(),
        
        // User Management Routes
        '/profile': (context) => const ProfileScreen(),
        '/associatedList': (context) => const AssociatedListScreen(),
        '/associatedForm': (context) => const AssociatedFormScreen(),
        '/userManagement': (context) => const UserManagementScreen(),
        
        // Customer Management Routes
        '/customersList': (context) => const CustomersListScreen(),
        '/customerForm': (context) => const CustomerFormScreen(),
        
        // Pool Management Routes
        '/poolsList': (context) => const PoolsListScreen(),
        '/poolForm': (context) => const PoolFormScreen(),
        '/poolDetails': (context) => const PoolDetailsScreen(poolId: ''),
        '/maintenanceForm': (context) => const MaintenanceFormScreen(),
        
        // Route Management Routes
        '/routesList': (context) => const RoutesListScreen(),
        '/routeDetails': (context) => const RouteDetailsScreen(route: {}),
        
        // Reports Routes
        '/reportsList': (context) => const ReportsListScreen(),
        '/reportDetails': (context) => const ReportDetailsScreen(report: {}),
        
        // Company Management Routes
        '/createCompany': (context) => const CreateCompanyScreen(),
        '/companiesList': (context) => const CompaniesListScreen(),
        '/companyRegistration': (context) => const CompanyRegistrationScreen(),
        '/companyManagement': (context) => const CompanyManagementScreen(),
      },
      builder: (context, child) {
        return AppBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      locale: const Locale('en'), // Set English as default
    );
  }
} 