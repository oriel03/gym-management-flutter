import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gym_management_app/providers/auth_provider.dart';

// Se muestra cuando el usuario abre el link de recuperación del email.
// Elige un PIN nuevo y queda logueado.
class NewPinScreen extends StatefulWidget {
  const NewPinScreen({super.key});

  @override
  State<NewPinScreen> createState() => _NewPinScreenState();
}

class _NewPinScreenState extends State<NewPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Misma regla que el registro: 6 dígitos (Supabase exige mínimo 6).
  String? _validatePin(String? v) {
    if (v == null || !RegExp(r'^\d{6}$').hasMatch(v)) {
      return 'El PIN tiene que tener 6 dígitos';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updatePin(_pin.text);
    if (!mounted || ok) return; // si ok, AuthWrapper cambia de pantalla solo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? 'No se pudo cambiar el PIN'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Elegí un PIN nuevo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _pin,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    validator: _validatePin,
                    decoration: const InputDecoration(
                      labelText: 'PIN nuevo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v != _pin.text ? 'Los PIN no coinciden' : null,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Repetí el PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
