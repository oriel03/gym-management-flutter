import 'package:flutter/material.dart';
import 'package:gym_management_app/components/component_Custom_Button.dart';
import 'package:gym_management_app/components/form_agregar_alumnos.dart';
import 'package:gym_management_app/models/student_details.dart';
import 'package:gym_management_app/providers/auth_provider.dart';
import 'package:gym_management_app/screens/auth_wrapper.dart';
import 'package:gym_management_app/services/supabase_service.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class ComponentListadoAlumnos extends StatefulWidget {
  // null = admin (ve todos los alumnos). Con valor = profesor (solo los suyos).
  final String? profesorId;

  const ComponentListadoAlumnos({super.key, this.profesorId});

  @override
  State<ComponentListadoAlumnos> createState() =>
      _ComponentListadoAlumnosState();
}

class _ComponentListadoAlumnosState extends State<ComponentListadoAlumnos> {
  static final log = Logger('ComponentListadoAlumnos');

  List<StudentDetails> alumnos = [];
  List<StudentDetails> filteredAlumnos = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  bool showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlumnos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cargar alumnos: admin ve todos, profesor ve solo los suyos.
  Future<void> _loadAlumnos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final List<StudentDetails> data;
      if (widget.profesorId == null) {
        data = await SupabaseService.getAllStudents(activeOnly: true);
      } else {
        data = await SupabaseService.getStudentsByProfesor(
          widget.profesorId!,
          activeOnly: true,
        );
      }
      if (mounted) {
        setState(() {
          alumnos = data;
          filteredAlumnos = data;
          isLoading = false;
        });
      }
    } catch (e) {
      log.warning('Error cargando alumnos', e);
      if (mounted) {
        setState(() {
          errorMessage = 'Error al cargar alumnos: $e';
          isLoading = false;
        });
      }
    }
  }

  // Navegar a formulario para agregar alumno
  Future<void> _onAddAlumno() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FormAgregarAlumno(profesorId: widget.profesorId ?? ''),
      ),
    );
    if (result == true) {
      await _loadAlumnos();
    }
  }

  // Desactivar alumno con confirmación (no se borra físicamente)
  Future<void> _onDeactivateAlumno(int alumnoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar desactivación'),
        content: Text('¿Estás seguro de que deseas desactivar este alumno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Desactivar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final result = await SupabaseService.desactivateStudent(alumnoId);

    if (!mounted) return;
    if (result['success'] == true) {
      await _loadAlumnos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error al desactivar alumno'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Filtrar alumnos según búsqueda (nombre o email; dni no está en la vista)
  void _filterAlumnos(String query) {
    setState(() {
      searchQuery = query.trim().toLowerCase();
      if (searchQuery.isEmpty) {
        filteredAlumnos = alumnos;
      } else {
        filteredAlumnos = alumnos.where((alumno) {
          final fullName = alumno.fullName.toLowerCase();
          final email = alumno.email.toLowerCase();
          return fullName.contains(searchQuery) || email.contains(searchQuery);
        }).toList();
      }
    });
  }

  // Mostrar diálogo de filtros (próximamente)
  void _showfilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Opciones de filtro próximamente')],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Construir barra de búsqueda
  Widget _buildSearchBar(bool isWideScreen) {
    if (!showSearch) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWideScreen ? 12.0 : 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterAlumnos(value),
        decoration: InputDecoration(
          hintText: 'Buscar Alumnos',
          prefixIcon: Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterAlumnos('');
                  },
                )
              : null,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF53AA70), width: 2),
          ),
        ),
      ),
    );
  }

  // Construir contenido principal
  Widget _buildContent(bool isWideScreen, bool isMobile) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
      );
    }
    if (alumnos.isEmpty) {
      return Center(
        child: Text(
          'No hay alumnos registrados.',
          style: TextStyle(fontSize: isMobile ? 14 : 16),
        ),
      );
    }
    final displayAlumnos = searchQuery.isNotEmpty ? filteredAlumnos : alumnos;
    if (displayAlumnos.isEmpty) {
      return Center(
        child: Text(
          'Sin resultados para "$searchQuery".',
          style: TextStyle(fontSize: isMobile ? 14 : 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: displayAlumnos.length,
      itemBuilder: (context, index) {
        final alumno = displayAlumnos[index];
        return _buildStudentTile(alumno, isWideScreen, isMobile);
      },
    );
  }
//AGREGAR NAVIGATIONTRAIL
  // Construir widget principal
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          final isMobile = constraints.maxWidth < 400;

          return Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 24.0 : 16.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  _buildHeader(isWideScreen),
                  SizedBox(height: 16),
                  _buildActionButtons(isWideScreen, isMobile),
                  SizedBox(height: 8),
                  _buildSearchBar(isWideScreen),
                  if (searchQuery.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Resultados encontrados: ${filteredAlumnos.length}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  Expanded(child: _buildContent(isWideScreen, isMobile)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Construir encabezado con botón de volver
  Widget _buildHeader(bool isWideScreen) {
    return Row(
      children: [
        IconButton(
          //CORREGIR LOGICA DEL BOTON BACK
          onPressed: () => const AuthWrapper(),
          icon: Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
        Expanded(
          child: Text(
            'Listado de Alumnos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: isWideScreen ? 20 : 18,
            ),
          ),
        ),
        SizedBox(width: 48),
      ],
    );
  }

  // Construir botones de acción
  Widget _buildActionButtons(bool isWideScreen, bool isMobile) {
    if (isMobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomButton.primary(
            onPressed: _onAddAlumno,
            text: 'Agregar',
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            icon: Icon(Icons.add, color: Colors.white, size: 20),
          ),
          CustomButton.primary(
            onPressed: _showfilterDialog,
            text: '',
            backgroundColor: Colors.black26,
            textColor: Colors.white,
            icon: Icon(Icons.filter_list, color: Colors.white, size: 20),
          ),
          CustomButton.primary(
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                if (!showSearch) {
                  searchQuery = '';
                  _searchController.clear();
                  _filterAlumnos('');
                }
              });
            },
            text: '',
            backgroundColor: showSearch ? Colors.black26 : Colors.transparent,
            textColor: showSearch ? Colors.white : Colors.black38,
            icon: Icon(
              Icons.search,
              color: showSearch ? Colors.white : Colors.black38,
              size: 20,
            ),
          ),
        ],
      );
    }
    // Para pantallas más anchas
    return Row(
      children: [
        CustomButton.withIcon(
          onPressed: _onAddAlumno,
          text: isWideScreen ? 'Agregar Alumno' : 'Agregar',
          backgroundColor: Colors.black54,
          textColor: Colors.white70,
          fontWeight: FontWeight.w600,
          icon: Icon(Icons.add, color: Colors.white70),
        ),
        SizedBox(width: 4),
        CustomButton.withIcon(
          onPressed: _showfilterDialog,
          text: 'Filtro',
          backgroundColor: Colors.black54,
          textColor: Colors.white70,
          fontWeight: FontWeight.w600, 
          icon: Icon(Icons.filter_list, color: Colors.white70),
        ),
        SizedBox(width: 4),
        CustomButton.withIcon(
          onPressed: () {
            setState(() {
              showSearch = !showSearch;
              if (!showSearch) {
                searchQuery = '';
                _searchController.clear();
                _filterAlumnos('');
              }
            });
          },
          text: 'Búsqueda',
          fontWeight: FontWeight.w500,
          backgroundColor: showSearch ? Colors.black26 : Colors.transparent,
          textColor: showSearch ? Colors.white : Colors.black38,
          icon: Icon(
            Icons.search,
            color: showSearch ? Colors.white : Colors.black38,
          ),
        ),
      ],
    );
  }
  
  // Calcular edad a partir de la fecha de nacimiento
  String _formatAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 'N/D';
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return '$age años';
  }
  // Abre la hoja de edición. Si se guardó (devuelve true), recarga la lista.
  // Antes el botón "Guardar" solo cerraba la hoja: no se guardaba nada.
  Future<void> _onEditAlumno(StudentDetails alumno) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditAlumnoSheet(alumno: alumno),
    );
    if (saved == true) await _loadAlumnos();
  }
  // Construir tarjeta de alumno
  Widget _buildStudentTile(
    StudentDetails alumno,
    bool isWideScreen,
    bool isMobile,
  ) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
//card de los alumnos cargados
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 16 : 12,
          vertical: isMobile ? 4 : 8,
        ),
        title: Text(
          alumno.fullName,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
            _formatAge(alumno.dateOfBirth),
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
          SizedBox(height: 2),
          //VER QUE MAS AGREGAR A LA CARD
          Text(
            'Plan: ${alumno.planName ?? "Sin plan"}'
            '${alumno.isPlanExpired ? " (vencido)" : ""}'
            '${alumno.isPlanAboutToExpire ? " (por vencer)" : ""}',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
          if(alumno.medicalConditions != null && alumno.medicalConditions!.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(alumno.medicalConditions ?? "Sin observaciones",
            style: TextStyle(
              fontSize: isMobile ? 12 : 14, 
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),)
          ]
           ],
          ),
        ),
        //MODIFICAR PARA AGREGAR LOS DOS ICONOS, EN ESTE CASO EDITA CUALQUIERA ELIMINA SOLO ADMIN
        // Solo el admin puede desactivar alumnos (coincide con la policy RLS)
        // Trailing con dos botones de acción dentro de un Row
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cualquier usuario autorizado puede editar
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          tooltip: 'Editar alumno',
          onPressed:() => _onEditAlumno(alumno),
          iconSize: isMobile ? 20 : 24,
        ),
        // Solo el admin puede desactivar/eliminar
        if (isAdmin)
          IconButton(
            icon: Icon(Icons.block, color: Colors.red),
            tooltip: 'Desactivar alumno',
            onPressed: () => _onDeactivateAlumno(alumno.studentId),
            iconSize: isMobile ? 20 : 24,
          ),
          
      ],
    ),
    onTap: () {
      // Navegación a detalles del alumno
    },
  ),
);

  }
}
// Hoja de edición de alumno. Es un StatefulWidget propio para poder crear
// y liberar (dispose) los TextEditingController correctamente.
class _EditAlumnoSheet extends StatefulWidget {
  const _EditAlumnoSheet({required this.alumno});
  final StudentDetails alumno;

  @override
  State<_EditAlumnoSheet> createState() => _EditAlumnoSheetState();
}

class _EditAlumnoSheetState extends State<_EditAlumnoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.alumno.firstName);
  late final _lastName = TextEditingController(text: widget.alumno.lastName);
  late final _email = TextEditingController(text: widget.alumno.email);
  late final _phone = TextEditingController(text: widget.alumno.phone ?? '');
  late final _emergency =
      TextEditingController(text: widget.alumno.emergencyContact ?? '');
  late final _medical =
      TextEditingController(text: widget.alumno.medicalConditions ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _lastName, _email, _phone, _emergency, _medical]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _nullIfEmpty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await SupabaseService.updateStudent(widget.alumno.studentId, {
      'name': _name.text.trim(),
      'last_name': _lastName.text.trim(),
      'email': _email.text.trim().toLowerCase(),
      'phone': _nullIfEmpty(_phone),
      'emergency_contact': _nullIfEmpty(_emergency),
      'medical_conditions': _nullIfEmpty(_medical),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alumno actualizado')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _field(TextEditingController c, String label,
      {String? Function(String?)? validator,
      TextInputType? keyboard,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboard,
        maxLines: maxLines,
        enabled: !_saving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar alumno',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_name, 'Nombre *', validator: _required),
              _field(_lastName, 'Apellido *', validator: _required),
              _field(_email, 'Email *',
                  validator: _required, keyboard: TextInputType.emailAddress),
              _field(_phone, 'Teléfono', keyboard: TextInputType.phone),
              _field(_emergency, 'Contacto de emergencia'),
              _field(_medical, 'Condiciones médicas', maxLines: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
