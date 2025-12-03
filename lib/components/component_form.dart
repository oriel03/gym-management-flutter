import 'package:flutter/material.dart';
import 'package:gym_management_app/services/supabase_service.dart';

class ComponentForm extends StatefulWidget {
  const ComponentForm({super.key});

  @override
  ComponentFormState createState() => ComponentFormState();
}

class ComponentFormState extends State<ComponentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  // Estados
  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _isLoading = false; //Estado de carga
  String? _selectedWorkArea; //Área de trabajo

  // En tu ComponentForm, cambia esta línea:
  final List<String> _workAreas = [
    'owner',
    'big_class_teacher',
    'small_class_teacher',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // Uso del mismo hash que SupabaseService
  // Ya no hasheamos aquí, lo hace SupabaseService

  // Validaciones (mantener las existentes + nueva)
  String? _validateWorkArea(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return 'Por favor selecciona tu área de trabajo';
    }
    return null;
  }

  // Conexión real con Supabase
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.loginUser(
        username: _usernameController.text.trim(),
        pin: _pinController.text, // PIN sin hashear
      );

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar('¡Bienvenido!', isError: false);
        // Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackBar(result['error'] ?? 'Error de autenticación');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Conexión real con Supabase
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.registerUser(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        pin: _pinController.text, // PIN sin hashear
        workArea: _selectedWorkArea!,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar('¡Cuenta creada exitosamente!', isError: false);
        _toggleMode(); // Cambiar a modo login
      } else {
        _showSnackBar(result['error'] ?? 'Error al crear la cuenta');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //Nueva funcion para mostrar dialogo de recuperacion de PIN
  void _showForgotPinDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          title: const Text(
            'Recuperar PIN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ingresa tu email y te enviaremos instrucciones para restablecer tu PIN',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'correo@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: _validateEmail,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                emailController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  await _handleForgotPin(emailController.text.trim());
                }
                emailController.dispose();
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  //Funcion para manejar la recuperacion de PIN
  Future<void> _handleForgotPin(String email) async {
    setState(() => _isLoading = true);

    try {
      final result = await SupabaseService.resetPassword(email: email);

      if (!mounted) return;

      if (result['success']) {
        _showSnackBar(
          'Email de recuperacion enviado. Revisa tu correo electronico',
          isError: false,
        );
      } else {
        _showSnackBar(
          result['error'] ?? 'Error al enviar email de recuperacion',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error de conexion $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _clearControllers();
      _selectedWorkArea = null; //Limpiar selección
    });
  }

  void _clearControllers() {
    _usernameController.clear();
    _emailController.clear();
    _nameController.clear();
    _pinController.clear();
    _confirmPinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(),
              const SizedBox(height: 24),
              ..._buildFormFields(),
              if (_isLogin) ...[
                const SizedBox(height: 16),
                _buildForgotPinLink(),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildToggleLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3232),
      ),
    );
  }

  //Widget para "olvidaste tu pin"

  Widget _buildForgotPinLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _isLoading ? null : _showForgotPinDialog,
          child: Text(
            '¿Olvidaste tu PIN?',
            style: TextStyle(
              color: _isLoading ? Colors.grey : Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[];

    // Campos específicos para registro
    if (!_isLogin) {
      fields.addAll([
        _buildTextField(
          controller: _nameController,
          label: 'Nombre Completo',
          hint: 'Ingresa tu nombre completo',
          validator: _validateName,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'ejemplo@correo.com',
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Dropdown para área de trabajo
        _buildWorkAreaDropdown(),
        const SizedBox(height: 16),
      ]);
    }

    // Campos comunes
    fields.addAll([
      _buildTextField(
        controller: _usernameController,
        label: 'Usuario',
        hint: 'Ingresa tu usuario',
        validator: _validateUsername,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _pinController,
        label: 'PIN',
        hint: _isLogin ? 'Ingresa tu PIN' : 'Crea un PIN (mín. 6 dígitos)',
        validator: _validatePin,
        obscureText: _obscurePassword,
        keyboardType: TextInputType.number,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    ]);

    // Confirmar PIN solo en registro
    if (!_isLogin) {
      fields.addAll([
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPinController,
          label: 'Confirmar PIN',
          hint: 'Confirma tu PIN',
          validator: _validateConfirmPin,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.number,
        ),
      ]);
    }

    return fields;
  }

  Widget _buildWorkAreaDropdown() {
    //map para mostrar mas legible
    final Map<String, String> workAreaLabels = {
      'owner': 'Propietario',
      'big_class_teacher': 'Profesor sala Grande',
      'small_class_teacher': 'Profesor sala Pequeña',
    };
    return DropdownButtonFormField<String>(
      initialValue: _selectedWorkArea,
      decoration: InputDecoration(
        labelText: 'Área de Trabajo',
        hintText: 'Selecciona tu área',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      validator: _validateWorkArea,
      items: _workAreas
          .map(
            (area) => DropdownMenuItem(
              value: area,
              child: Text(workAreaLabels[area] ?? area),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedWorkArea = value),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // Botón con loading
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C3232),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading
            ? null
            : (_isLogin ? _handleLogin : _handleRegister),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Widget duplicado arreglado
  Widget _buildToggleLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _toggleMode,
            child: Text(
              _isLogin ? 'Regístrate aquí' : 'Inicia sesión',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validaciones existentes (mantener todas las que ya tienes)
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el usuario';
    }
    if (value.trim().length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el PIN';
    }
    final minLength = _isLogin ? 4 : 6;
    if (value.length < minLength) {
      return _isLogin
          ? 'El PIN debe tener al menos 4 dígitos'
          : 'El PIN debe tener al menos 6 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El PIN solo debe contener números';
    }
    return null;
  }

  String? _validateConfirmPin(String? value) {
    if (!_isLogin) {
      if (value == null || value.isEmpty) {
        return 'Por favor confirma tu PIN';
      }
      if (value != _pinController.text) {
        return 'Los PINs no coinciden';
      }
    }
    return null;
  }
}
