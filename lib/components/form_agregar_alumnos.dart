import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_management_app/services/supabase_service.dart';

class FormAgregarAlumno extends StatefulWidget {
  final String profesorId;

  const FormAgregarAlumno({super.key, required this.profesorId});

  @override
  State<FormAgregarAlumno> createState() => _FormAgregarAlumnoState();
}

class _FormAgregarAlumnoState extends State<FormAgregarAlumno> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dniController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  // Estados
  bool _isLoading = false;
  DateTime? _selectedDate;
  String? _selectedPlanId;
  List<Map<String, dynamic>> _planes = [];
  String _selectedSchedule = 'Mañana';

  final List<String> _schedules = ['Mañana', 'Tarde', 'Noche'];

  @override
  void initState() {
    super.initState();
    _loadPlanes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  // Cargar planes disponibles
  Future<void> _loadPlanes() async {
    try {
      final response = await Supabase.instance.client
          .from('plans')
          .select('id, name, monthly_price');
          

      if (mounted) {
        setState(() {
          _planes = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showSnackBar('Error al cargar planes: $e');
    }
  }

  // Manejar envío del formulario
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Una sola llamada: la base crea el alumno y su plan juntos, o ninguno.
      // Los campos vacíos los convierte a null la función SQL.
      final result = await SupabaseService.createStudentWithPlan(
        student: {
          'name': _nameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'dni': _dniController.text,
          'phone': _phoneController.text,
          // Solo la fecha (yyyy-mm-dd): la columna es de tipo date.
          'date_of_birth': _selectedDate?.toIso8601String().split('T').first,
          'emergency_contact': _emergencyContactController.text,
          // Antes se guardaba el NOMBRE del contacto en este campo.
          'emergency_phone': _emergencyPhoneController.text,
          'medical_conditions': _medicalConditionsController.text,
        },
        planId: _selectedPlanId != null ? int.parse(_selectedPlanId!) : null,
        // El admin llega con profesorId vacío (''), que no es un uuid válido
        // y hacía fallar el alta del plan. null = "el usuario logueado".
        profesorId: widget.profesorId.isEmpty ? null : widget.profesorId,
        preferredShift: _selectedSchedule.toLowerCase(),
      );

      if (!mounted) return;
      if (result['success'] == true) {
        _showSnackBar('¡Alumno creado exitosamente!', isError: false);
        Navigator.pop(context, true); // true = recargar la lista
      } else {
        _showSnackBar(result['error'] as String);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mostrar SnackBar
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Seleccionar fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromRGBO(218, 165, 32, 1.0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // Construir UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          textAlign: TextAlign.left,
          'Agregar Nuevo Alumno',
          style: TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: Color.fromRGBO(52, 52, 52, 1.0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _buildForm(),
        ),
      ),
    );
  }

  // Construir formulario
  Widget _buildForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Personal'),
              const SizedBox(height: 16),

              // Nombre
              _buildTextField(
                controller: _nameController,
                label: 'Nombre *',
                hint: 'Ingresa el nombre',
                validator: _validateRequired,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Apellido
              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido *',
                hint: 'Ingresa el apellido',
                validator: _validateRequired,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email *',
                hint: 'ejemplo@correo.com',
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Teléfono
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                hint: 'Número de teléfono',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // DNI
              _buildTextField(
                controller: _dniController,
                label: 'DNI *', // obligatorio en la base (NOT NULL + único)
                hint: 'Documento de identidad',
                keyboardType: TextInputType.number,
                validator: _validateRequired,
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              _buildDatePicker(),
              const SizedBox(height: 24),
              // contacto de emergencia
              _buildSectionTitle('Contacto de Emergencia'),
              const SizedBox(height: 16),

              // Contacto de emergencia
              _buildTextField(
                controller: _emergencyContactController,
                label: 'Nombre de contacto',
                hint: 'Persona a contactar',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Teléfono de emergencia
              _buildTextField(
                controller: _emergencyPhoneController,
                label: 'Teléfono de emergencia',
                hint: 'Número de emergencia',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('informacion Medica'),
              const SizedBox(height: 16),
              _buildTextField(controller: _medicalConditionsController,
               label: 'Patalogias / Condiciones medicas', 
               hint: 'Ej: Hipertension, diabetes, lesion de rodilla...',
               maxLines: 3,
               ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Información del Plan'),
              const SizedBox(height: 16),

              // Dropdown de planes
              _buildPlanDropdown(),
              const SizedBox(height: 16),

              // Horario
              _buildScheduleDropdown(),
              const SizedBox(height: 16),

              // Botón de enviar
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Título de sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3232),
      ),
    );
  }

  // Campo de texto genérico
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Color.fromRGBO(218, 165, 32, 1.0),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  // Selector de fecha
  Widget _buildDatePicker() {
    return InkWell(
      onTap: _isLoading ? null : _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de Nacimiento',
          hintText: 'Selecciona la fecha',
          suffixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Text(
          _selectedDate == null
              ? 'No seleccionada'
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          style: TextStyle(
            color: _selectedDate == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }

  // Dropdown de planes
  Widget _buildPlanDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPlanId,
      decoration: InputDecoration(
        labelText: 'Plan',
        hintText: 'Selecciona un plan',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text('Sin plan asignado')),
        ..._planes.map(
          (plan) => DropdownMenuItem<String>(
            value: plan['id'].toString(),
            child: Text('${plan['name']} - \$${plan['monthly_price']}'),
          ),
        ),
      ],
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() => _selectedPlanId = value);
            },
    );
  }

  // Dropdown de horario
  Widget _buildScheduleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSchedule,
      decoration: InputDecoration(
        labelText: 'Horario *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      validator: _validateRequired,
      items: _schedules
          .map(
            (schedule) => DropdownMenuItem<String>(
              value: schedule,
              child: Text(schedule),
            ),
          )
          .toList(),
      onChanged: _isLoading
          ? null
          : (value) {
              if (value != null) setState(() => _selectedSchedule = value);
            },
    );
  }

  // Botón de enviar
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(52, 52, 52, 1.0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : _handleSubmit,
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
                'Crear Alumno',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Validaciones
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

}