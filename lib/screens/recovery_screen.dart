import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
/* Recuperación con Supabase Auth: Supabase manda un email con un link
   seguro y de un solo uso. Al abrirlo, la app recibe el evento
   passwordRecovery y muestra NewPinScreen. El PIN nunca viaja por email
   ni pasa por nuestro código. */
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final log = Logger('RecoveryScreen');
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _recuperarPin() async {
    String email = _emailController.text.trim();

    // Validación mejorada
    if (email.isEmpty) {
      _mostrarMensaje('Por favor ingresa tu email', Colors.orange);
      return;
    }

    if (!_esEmailValido(email)) {
      _mostrarMensaje('Por favor ingresa un email válido', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // No logueamos el email: es un dato personal.
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.toLowerCase(),
        // En web, el link vuelve a la misma URL donde corre la app.
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
      _mostrarEnviado();
    } on AuthException catch (e, st) {
      log.warning('resetPasswordForEmail falló status=${e.statusCode}', e, st);
      if (e.statusCode == '429') {
        _mostrarMensaje(
            'Pediste muchos links seguidos. Esperá unos minutos.', Colors.orange);
      } else {
        // Mismo mensaje exista o no el email (no revelamos quién tiene cuenta)
        _mostrarEnviado();
      }
    } catch (e, st) {
      log.severe('Error inesperado en _recuperarPin', e, st);
      _mostrarMensaje('Error de conexión. Verificá tu internet.', Colors.red);
    } finally {
      // Antes _isLoading nunca volvía a false y el botón quedaba bloqueado
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarEnviado() {
    _mostrarMensaje(
        'Si el email está registrado, te llegó un link para elegir un PIN nuevo.',
        Colors.green);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  bool _esEmailValido(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar PIN'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Recuperación de PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresá tu email y te enviamos un link para elegir un PIN nuevo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'ejemplo@correo.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onSubmitted: (_) => _recuperarPin(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _recuperarPin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enviar link',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
