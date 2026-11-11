import 'package:flutter/material.dart';
import 'package:gym_management_app/providers/auth_provider.dart';
import 'package:gym_management_app/services/supabase_service.dart';
import 'package:provider/provider.dart';

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
    'big_class',
    'small_class',
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
  // Las modificaciones son a raiz de la delegacion de pasos en vez de manejar el la sesion manualmente 
  // se Delega a AuthProvider que maneja la sesion y navega automaticamente
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().login(
        _usernameController.text.trim(),
        _pinController.text,
        );
      

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else{
        final error = context.read<AuthProvider>().errorMessage;
        _showSnackBar(error ?? 'Credenciales invalidas');
     }
    
    }
    catch (e) {
      if(mounted) _showSnackBar('Error de conexion: $e');
    }finally {
      if(mounted) setState(() => _isLoading = false);
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
              const SizedBox(height: 12),

              //link de recuperar pin
              if (_isLogin) _recoverPinLink(),
              const SizedBox(height: 16),
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

  Widget _recoverPinLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Navegar a la pantalla de recuperación de PIN
          Navigator.pushNamed(context, '/send-recovery-pin');
        },
        child: const Text(
          '¿Olvidaste tu PIN?',
          style: TextStyle(color: Colors.blue),
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
        maxLength: 6,
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
      'admin': 'Propietario',
      'big_class': 'Profesor sala Grande',
      'small_class': 'Profesor sala Pequeña',
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
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
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
    if (value == null || value.isEmpty) return 'Por favor ingresa el PIN';
    if(!RegExp(r'^\d+$').hasMatch(value)) return 'solo numeros';
    if(_isLogin && value.length < 4) return 'minimo 4 digitos';
    if(!_isLogin && value.length != 6) return 'El PIN debe tener exactamente 6 digitos';
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
