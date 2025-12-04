import 'package:flutter/material.dart';
import 'package:gym_management_app/services/email_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
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
      print('🔍 Buscando usuario con email: $email');

      // Buscar usuario en Supabase
      final response = await Supabase.instance.client
          .from('users')
          .select('pin')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        print('❌ Usuario no encontrado');
        if (mounted) {
          _mostrarMensaje('Email no registrado en el sistema', Colors.red);
        }
        return;
      }

      String pin = response['pin'].toString();
      print('✅ Usuario encontrado, PIN: $pin');

      // Enviar email
      print('📧 Intentando enviar email...');
      bool enviado = await EmailServices.enviarPinRecuperacion(
        email: email,
        pin: pin,
      );

      if (mounted) {
        if (enviado) {
          print('✅ Email enviado exitosamente');
          _mostrarMensaje('📧 Revisa tu email', Colors.green);

          // Volver al login después de 2 segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          print('❌ Error al enviar email');
          _mostrarMensaje(
            'No se pudo enviar el email. Verifica tu conexión.',
            Colors.red,
          );
        }
      }
    } on PostgrestException catch (e) {
      print('❌ Error de Supabase: ${e.message}');
      if (mounted) {
        _mostrarMensaje('Error de base de datos: ${e.message}', Colors.red);
      }
    } catch (e, stackTrace) {
      print('❌ Error inesperado: $e');
      print('📍 StackTrace: $stackTrace');
      if (mounted) {
        _mostrarMensaje('Error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                'Ingresa tu email y te enviaremos tu PIN',
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
                          'Enviar PIN',
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
