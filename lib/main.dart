import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/services/firebase_auth_repository.dart';
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
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shinning_pools_flutter/features/companies/viewmodels/company_notification_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Main: Error initializing Firebase: $e');
    }
    rethrow;
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
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(
            context.read<FirebaseAuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<NavigationService>(
          create: (_) => NavigationService.instance,
        ),
        ChangeNotifierProvider<PoolService>(
          create: (_) => PoolService(),
        ),
        ChangeNotifierProvider<CompanyService>(
          create: (_) => CompanyService(),
        ),
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
          create: (context) => CustomerViewModel(
            customerRepository: CustomerRepository(),
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<CompanyNotificationViewModel>(
          create: (context) => CompanyNotificationViewModel(
            invitationRepository: context.read<WorkerInvitationRepository>(),
            authService: context.read<AuthService>(),
          ),
        ),
      ],
      child: const ShinningPoolsApp(),
    ),
  );
}
