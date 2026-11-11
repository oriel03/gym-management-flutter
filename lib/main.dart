import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_management_app/core/config/env.dart';
import 'package:gym_management_app/providers/auth_provider.dart';
import 'package:gym_management_app/screens/auth_wrapper.dart';
import 'package:gym_management_app/screens/dashboard_screen.dart';
import 'package:gym_management_app/screens/login_screen.dart';
import 'package:gym_management_app/screens/recovery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fallar rápido y con un mensaje claro si faltan los --dart-define.
  // Sin esto, Supabase falla más adelante con un error difícil de entender.
  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL / SUPABASE_ANON_KEY. Corré la app con '
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const GymApp(),
    ),
  );
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // component_form.dart navega a esta ruta desde "¿Olvidaste tu PIN?"
        '/send-recovery-pin': (context) => const RecoveryScreen(),
      },
    );
  }
}
