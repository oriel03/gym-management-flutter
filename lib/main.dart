import 'package:flutter/material.dart';
//import 'package:gym_management_app/components/component_listado_alumnos.dart';
import 'package:gym_management_app/screens/dashboard_screen.dart';
//import 'package:gym_management_app/components/component_form.dart';

//import 'package:gym_management_app/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Importar pantallas (vas a crear estos archivos después)
// import 'screens/login_screen.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/students_screen.dart';
// import 'screens/add_student_screen.dart';
// import 'screens/plans_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cargar .env
  await dotenv.load(fileName: ".env");

  // REEMPLAZAR CON TUS CREDENCIALES CORRECTAS
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valhalla Gym Management',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),

      home: const DashboardScreen(),

      //initialRoute: '/', // Pantalla inicial
      //routes: {
      // RUTA PRINCIPAL - LOGIN
      //'/': (context) => const ComponentForm(),
      //},
    );
  }
}
