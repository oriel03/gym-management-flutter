import 'package:flutter/material.dart';
import 'package:gym_management_app/components/component_Custom_Button.dart';

import 'package:gym_management_app/components/form_agregar_alumnos.dart';
import 'package:gym_management_app/screens/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_management_app/models/student.dart';

class ComponentListadoAlumnos extends StatefulWidget {
  final String profesorId;
  const ComponentListadoAlumnos({super.key, required this.profesorId});

  @override
  State<ComponentListadoAlumnos> createState() =>
      _ComponentListadoAlumnosState();
}

class _ComponentListadoAlumnosState extends State<ComponentListadoAlumnos> {
  List<Student> alumnos = [];
  List<Student> filteredAlumnos = [];
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

  //Cargar alumnos desde Supabase
  Future<void> _loadAlumnos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('*, plans(*), users(*)')
          .eq('profesor_id', widget.profesorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          alumnos = (response as List)
              .map((json) => Student.fromJson(json))
              .toList();
          filteredAlumnos = alumnos;
          isLoading = false;
        });
      }
    } catch (e) {
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
        builder: (context) => FormAgregarAlumno(profesorId: widget.profesorId),
      ),
    );
    if (result == true) {
      _loadAlumnos();
    }
  }

  // Eliminar alumno con confirmación
  Future<void> _onDeleteAlumno(String alumnoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar este alumno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('students')
          .delete()
          .eq('id', alumnoId);

      if (mounted) {
        setState(() {
          alumnos.removeWhere((alumno) => alumno.id == alumnoId);
          filteredAlumnos.removeWhere((alumno) => alumno.id == alumnoId);
        });
        _loadAlumnos();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar alumno: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Filtrar alumnos según búsqueda
  void _filterAlumnos(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        filteredAlumnos = alumnos;
      } else {
        filteredAlumnos = alumnos.where((alumno) {
          final fullName = '${alumno.name}${alumno.lastName}'.toLowerCase();
          final email = alumno.email.toLowerCase();
          final dni = alumno.dni?.toLowerCase() ?? '';
          final planLower = alumno.planId?.toLowerCase() ?? '';
          return fullName.contains(searchQuery) ||
              email.contains(searchQuery) ||
              dni.contains(searchQuery) ||
              planLower.contains(searchQuery);
        }).toList();
      }
    });
  }

  // Mostrar diálogo de filtros (próximamente) -> Ver de que forma
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
    return ListView.builder(
      itemCount: displayAlumnos.length,
      itemBuilder: (context, index) {
        final alumno = displayAlumnos[index];
        return _buildStudentTile(alumno, isWideScreen, isMobile);
      },
    );
  }

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
          onPressed: () => DashboardScreen(),
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

  // Construir tarjeta de alumno
  Widget _buildStudentTile(Student alumno, bool isWideScreen, bool isMobile) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 16 : 12,
          vertical: isMobile ? 4 : 8,
        ),
        title: Text(
          '${alumno.name} ${alumno.lastName}',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Edad: ${alumno.age}, Plan: ${alumno.planId}',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _onDeleteAlumno(alumno.id),
          iconSize: isMobile ? 20 : 24,
        ),
        onTap: () {
          // Aquí puedes navegar a detalles del alumno
        },
      ),
    );
  }
}
