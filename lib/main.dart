import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/customer_repository.dart';
import 'core/services/worker_repository.dart';
import 'core/services/worker_invitation_repository.dart';
import 'features/pools/services/pool_service.dart';
import 'features/companies/services/company_service.dart';
import 'features/users/viewmodels/invitation_viewmodel.dart';
import 'features/users/viewmodels/worker_viewmodel.dart';
import 'features/customers/viewmodels/customer_viewmodel.dart';
import 'core/app.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:shinning_pools_flutter/features/companies/viewmodels/company_notification_viewmodel.dart';
import 'package:shinning_pools_flutter/features/routes/viewmodels/route_viewmodel.dart';
import 'package:shinning_pools_flutter/features/routes/viewmodels/assignment_viewmodel.dart';
import 'package:shinning_pools_flutter/core/services/firebase_auth_repository.dart';
import 'package:shinning_pools_flutter/features/routes/services/assignment_service.dart';
import 'package:shinning_pools_flutter/features/routes/services/assignment_validation_service.dart';

import 'package:shinning_pools_flutter/core/services/route_repository.dart';
import 'package:shinning_pools_flutter/core/services/pool_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    rethrow;
  }

  // Set persistence for web only
  if (kIsWeb) {
    await fb_auth.FirebaseAuth.instance.setPersistence(
      fb_auth.Persistence.LOCAL,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseAuthRepository>(
          create: (_) => FirebaseAuthRepository(),
        ),
        Provider<WorkerInvitationRepository>(
          create: (_) => WorkerInvitationRepository(),
        ),
        Provider<CustomerRepository>(create: (_) => CustomerRepository()),
        Provider<WorkerRepository>(create: (_) => WorkerRepository()),
        Provider<RouteRepository>(create: (_) => RouteRepository()),
        Provider<PoolRepository>(create: (_) => PoolRepository()),
        ChangeNotifierProvider<AuthService>(
          create: (context) =>
              AuthService(context.read<FirebaseAuthRepository>()),
        ),
        ChangeNotifierProxyProvider<AuthService, AssignmentService>(
          create: (context) =>
              AssignmentService(authService: context.read<AuthService>()),
          update: (context, authService, previous) =>
              AssignmentService(authService: authService),
        ),
        Provider<AssignmentValidationService>(
          create: (context) => AssignmentValidationService(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<NavigationService>(
          create: (_) => NavigationService.instance,
        ),
        ChangeNotifierProvider<PoolService>(create: (_) => PoolService()),
        ChangeNotifierProvider<CompanyService>(create: (_) => CompanyService()),
        ChangeNotifierProvider<InvitationViewModel>(
          create: (context) => InvitationViewModel(
            invitationRepository: context.read<WorkerInvitationRepository>(),
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<WorkerViewModel>(
          create: (context) => WorkerViewModel(
            workerRepository: WorkerRepository(),
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<CustomerViewModel>(
          create: (context) {
            return CustomerViewModel(
              customerRepository: CustomerRepository(),
              authService: context.read<AuthService>(),
            );
          },
        ),
        ChangeNotifierProvider<CompanyNotificationViewModel>(
          create: (context) => CompanyNotificationViewModel(
            invitationRepository: context.read<WorkerInvitationRepository>(),
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<AssignmentViewModel>(
          create: (context) => AssignmentViewModel(
            context.read<AuthService>(),
            context.read<AssignmentService>(),
          ),
        ),
        ChangeNotifierProvider<RouteViewModel>(
          create: (context) => RouteViewModel(),
        ),
      ],
      child: const ShinningPoolsApp(),
    ),
  );
}
