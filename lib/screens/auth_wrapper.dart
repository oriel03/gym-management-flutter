import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gym_management_app/providers/auth_provider.dart';
import 'package:gym_management_app/screens/dashboard_screen.dart';
import 'package:gym_management_app/screens/login_screen.dart';
import 'package:gym_management_app/screens/new_pin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // switch exhaustivo: si mañana agregás otro AuthStatus, el compilador
    // te obliga a decidir qué pantalla mostrar.
    return switch (authProvider.status) {
      AuthStatus.checking =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.authenticated => const DashboardScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.recovering => const NewPinScreen(),
    };
  }
}
