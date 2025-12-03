import 'package:flutter/material.dart';
import 'package:gym_management_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkRecoveryToken();
  }

  //detectar token de recuperacion
  Future<void> _checkRecoveryToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        if (mounted) {
          _showSnackBar('Token de recuperación inválido o expirado');
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al verificar el token de recuperación: $e');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPinController,
                decoration: const InputDecoration(labelText: 'Nuevo PIN'),
                obscureText: _obscurePassword,
                keyboardType: TextInputType.number,
                validator: _validatePin,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _confirmPinController,
                decoration: const InputDecoration(labelText: 'Confirmar PIN'),
                obscureText: _obscurePassword,
                keyboardType: TextInputType.number,
                validator: _validateConfirmPin,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _handleResetPassword, // ✓ Sin cambios
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Actualizar PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el PIN';
    }

    if (value.length < 6) {
      return 'El PIN debe tener al menos 6 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El PIN solo debe contener números';
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu PIN';
    }
    if (value != _newPinController.text) {
      return 'Los PINs no coinciden';
    }
    return null;
  }

  //manejar la recuperacion del pin
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return; // ✓ Agregado el !

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.updatePassword(
        newPin: _newPinController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar(
          '¡PIN actualizado exitosamente!',
          isError: false,
        ); // ✓ Con _
        // Esperar un momento para que el usuario vea el mensaje
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Regresar al login
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _showSnackBar(result['error'] ?? 'Error al actualizar PIN'); // ✓ Con _
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error de conexión: $e'); // ✓ Con _
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
