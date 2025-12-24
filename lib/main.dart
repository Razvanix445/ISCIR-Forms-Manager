import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iscir_forms_app/screens/forms/form_edit_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/client_provider.dart';
import 'providers/form_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/clients/client_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await DatabaseService.instance.database;
  runApp(const ISCIRFormsApp());
}

class ISCIRFormsApp extends StatelessWidget {
  const ISCIRFormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => FormProvider()),
      ],
      child: const AppWithRouter(),
    );
  }
}

class AppWithRouter extends StatefulWidget {
  const AppWithRouter({super.key});

  @override
  State<AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<AppWithRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<MyAuthProvider>();
    _router = _createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ISCIR Forms',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(MyAuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/clients',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        if (isLoggedIn && isLoggingIn) {
          return '/clients';
        }

        return null;
      },
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientsScreen(),
        ),
        GoRoute(
          path: '/clients/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ClientDetailScreen(clientId: id);
          },
        ),
        GoRoute(
          path: '/clients/:clientId/forms/:formId/edit',
          builder: (context, state) {
            final clientId = state.pathParameters['clientId']!;
            final formId = state.pathParameters['formId']!;
            return FormEditWrapper(formId: formId,);
          },
        ),
      ],
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: child,
    );
  }
}

class ModernHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showBackButton; // New parameter to control back button

  const ModernHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = true, // Default to true - show back button automatically
  });

  @override
  Widget build(BuildContext context) {
    // Check if we CAN go back
    final canPop = GoRouter.of(context).canPop();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button - only show if we can go back AND showBackButton is true
          if (canPop && showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}