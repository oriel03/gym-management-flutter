import 'package:flutter/material.dart';
import 'package:gym_management_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:gym_management_app/providers/auth_provider.dart';
//importa tus screens existentes
import 'package:gym_management_app/screens/login_screen.dart';
import 'package:gym_management_app/screens/dashboard_screen.dart';
import 'package:gym_management_app/screens/new_pin_screen.dart';
// import 'package:gym_management_app/screens/admin_dashboard.dart'; // cuando la tengas

// SplashScreen -> pantalla de carga mientras se verifica la sesion guardada
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  
  Widget build(BuildContext context){
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      )
    );
  }
}

//AppRouter -> Decide que pantalla mostrar mediante el AuthProvider

class AppRouter extends StatelessWidget{
  const AppRouter ({super.key});

  @override
  Widget build(BuildContext context){
    //watch -> se reconstruye cada vez que AuthStatus cambia
    final authStatus = context.watch<AuthProvider>().status;
    final user = context.watch<AuthProvider>().user;

    switch(authStatus){
      //verificando sesion guardada -> spinner
      case AuthStatus.checking:
        return const SplashScreen();
      // no hay sesion -> login
      case AuthStatus.unauthenticated:
      return const LoginScreen();
      // abrió el link de recuperación -> elegir PIN nuevo
      case AuthStatus.recovering:
      return const NewPinScreen();
      // hay sesion -> redirigir segun rol
      case AuthStatus.authenticated:
      if(user == null) return const LoginScreen();

    switch (user.workArea){
      case WorkArea.admin: 
        //return const AdminDashboard();
      return const DashboardScreen(); //temporal hasta dashboardAdmin
      case WorkArea.bigClass:
      case WorkArea.smallClass:
      return const DashboardScreen();
      default:
        //rol desconocido -> logout por seguridad
      WidgetsBinding.instance.addPostFrameCallback((_){
        context.read<AuthProvider>().logout();
        });
      return const LoginScreen();
      }
      
      }
    }
  }
