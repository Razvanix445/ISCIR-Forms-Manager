import 'package:flutter/material.dart';
import 'package:iscir_forms_app/screens/coordinate_mapping_screen.dart';
import 'package:iscir_forms_app/screens/forms/form_edit_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/client_provider.dart';
import 'providers/form_provider.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/clients/client_detail_screen.dart';

import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  runApp(const ISCIRFormsApp());
}

class ISCIRFormsApp extends StatelessWidget {
  const ISCIRFormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => FormProvider()),
      ],
      child: MaterialApp.router(
        title: 'ISCIR Forms Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'NotoSans',
        ),
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ClientsScreen(),
      // builder: (context, state) => const CoordinateMappingScreen(),
    ),
    GoRoute(
      path: '/client/:clientId',
      builder: (context, state) {
        final clientId = int.parse(state.pathParameters['clientId']!);
        return ClientDetailScreen(clientId: clientId);
      },
    ),
    GoRoute(
      path: '/form/:formId/edit',
      builder: (context, state) {
        final formId = int.parse(state.pathParameters['formId']!);
        return FormEditWrapper(formId: formId);
      },
    ),
  ],
);