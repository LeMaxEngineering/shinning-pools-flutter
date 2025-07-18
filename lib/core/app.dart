import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/auth_wrapper.dart';
import 'package:shinning_pools_flutter/features/auth/screens/login_screen.dart';
import 'package:shinning_pools_flutter/features/auth/screens/register_screen.dart';
import 'package:shinning_pools_flutter/features/companies/screens/companies_list_screen.dart';
import 'package:shinning_pools_flutter/features/routes/models/route.dart';
import 'package:shinning_pools_flutter/features/routes/screens/route_details_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/route_map_screen.dart';
import 'package:shinning_pools_flutter/features/routes/screens/routes_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/models/worker_invitation.dart';
import 'package:shinning_pools_flutter/features/users/screens/associated_list_screen.dart';
import 'package:shinning_pools_flutter/features/users/screens/invitation_notification_screen.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/app_theme.dart';
import 'package:shinning_pools_flutter/features/auth/screens/email_verification_screen.dart';
import 'package:shinning_pools_flutter/l10n/l10n.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/company_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/associated_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/customer_dashboard.dart';
import 'package:shinning_pools_flutter/features/dashboard/screens/dashboard_screen.dart';

class ShinningPoolsApp extends StatelessWidget {
  const ShinningPoolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shinning Pools',
      theme: appTheme,
      home: AuthWrapper(),
      localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
      ],
      routes: {
        '/auth': (context) => AuthWrapper(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/email-verification': (context) => EmailVerificationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/companyDashboard': (context) => const CompanyDashboard(),
        '/associatedDashboard': (context) => const AssociatedDashboard(),
        '/customerDashboard': (context) => const CustomerDashboard(),
        '/companies': (context) => CompaniesListScreen(),
        '/route-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RouteDetailsScreen(routeId: args['routeId']);
        },
        '/route-map': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RouteMapScreen(route: args['route']);
        },
        '/routes': (context) => RoutesListScreen(),
        '/associated-list': (context) => AssociatedListScreen(),
        '/invitation-notification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return InvitationNotificationScreen(invitation: args['invitation']);
        },
        },
    );
  }
} 