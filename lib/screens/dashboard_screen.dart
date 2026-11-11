import 'dart:ui';
import 'package:gym_management_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:calendar_view/calendar_view.dart';
import 'package:gym_management_app/components/component_list_alumnos.dart';
import 'package:gym_management_app/models/user.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:gym_management_app/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
  
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  late EventController _eventController;
  final FocusNode _menuButtonFocusNode = FocusNode(debugLabel: 'Menu Button');
  final FocusNode _profileButtonFocusNode = FocusNode(
    debugLabel: 'Profile Button',
  );
  //Variables para manejar estados
  int _pendingUsersCount = 0;
  List<UserModel> _pendingUsers = [];
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  @override
  void initState() {
    super.initState();
    _eventController = EventController();
    _loadPendingUsers();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _eventController.dispose();
    _menuButtonFocusNode.dispose();
    _profileButtonFocusNode.dispose();
    super.dispose();
  }
  //obtener id del profesor logueado

  //Se crean los metodos de navegacion
  /*
Void _navigateToFinanzas(){
}
*/
  Future<void> _loadPendingUsers() async {
    final users = await SupabaseService.getPendingUsers();
    if(mounted) {
      setState((){
        _pendingUsers = users;
        _pendingUsersCount = users.length;
      });
    }
  }

// Ver a los usuarios pendientes
void _showPendingUserSheet(){
  showModalBottomSheet(
    context: context, 
    backgroundColor: Color.fromRGBO(44, 50, 50, 0.95),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _buildPendingUsersSheet(),);
}
  //Se crea para navegar al componentes de listado de alumnos //Se pasa el id del profesor logueado
 //se incorpora un guard clause para evitar un pedido de id erroneo o inexsistente
  void navigateToAlumnos() {
    final user = context.read<AuthProvider>().user;
    if(user == null ) { 
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('debe iniciar sesion')),
        );
    return;
    }
    final isAdmin = user.workArea == WorkArea.admin;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentListadoAlumnos(
          profesorId: isAdmin ? null : user.id,
        ),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a Alumnos')));
  }

  //Se crea para navegar al componentes de listado de pagos => tiene que ser con el alias de cada profesor
  void navigateToPagos() {
    Navigator.pop(context);
    //Navigator.push(context, MaterialPageRoute(builder:context) => ComponentListadoPagos(),));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a Pagos')));
  }

  //Se crea para navegar al componentes de perfil -> editar perfil
  void navigateToPerfil() {
    Navigator.pop(context);
    //Navigator.push(context, MaterialPageRoute(builder:context) => ComponentPerfil(),));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a Perfil')));
  }

  void _navigateToConfiguracion() {
    Navigator.pop(context);
    //Navigator.push(context, MaterialPageRoute(builder:context) => ComponentConfiguracion(),));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navegando a Configuración')));
  }

  //Cerrar sesión
  void _logout() {
    Navigator.pop(context);
    //Lógica de cierre de sesión
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica de cierre de sesión aquí
              Navigator.pop(context); // Cerrar el diálogo
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Sesión cerrada')));
            },
            child: Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.workArea == WorkArea.admin;
    
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Fondo con gradiente
            _buildBackground(),

            // Navbar flotante
            _buildNavbar(isAdmin),

            // Contenido principal
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              bottom: 16,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Bienvenida
                        _buildWelcomeSection(isDesktop),

                        SizedBox(height: isDesktop ? 16 : 12),

                        // Calendario
                        _buildCalendar(isDesktop, constraints),

                        SizedBox(height: isDesktop ? 24 : 16),

                        // Listado de alumnos
                        _buildStudentsList(isDesktop),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SECCIONES SEPARADAS ============

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(44, 50, 50, 1),
            Color.fromRGBO(218, 165, 32, 0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(bool isAdmin) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(44, 50, 50, 0.9),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Menu principal
                MenuAnchor(
                  childFocusNode: _buttonFocusNode,
                  menuChildren: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Gestion',
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Divider(),
                    //Estos son los que faltarian agregar
                    /* -> 
                    MenuItemButton(
                      onPressed: () => _activateMenuEntry(MenuEntry.pagos),
                      child: Text(
                        MenuEntry.pagos.label,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ), 
                    MenuItemButton(
                      onPressed: _navigateTofinanzas,
                      child: Text(
                        MenuEntry.alumnos.label,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),*/
                    MenuItemButton(
                      onPressed: navigateToAlumnos,
                      child: Text(
                        'Listado de alumnos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    MenuItemButton(
                      onPressed: navigateToPagos,
                      child: Text(
                        'Pagos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    Divider(color: Colors.white38, height: 1),
                    MenuItemButton(
                      onPressed: _navigateToConfiguracion,
                      child: Text(
                        'Configuración',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                  style: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Color.fromRGBO(44, 50, 50, 0.9),
                    ),
                    elevation: WidgetStateProperty.all(4),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return IconButton(
                      focusNode: _buttonFocusNode,
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      icon: Icon(Icons.menu, color: Colors.white, size: 25),
                      tooltip: 'Menú',
                    );
                  },
                ),

                Spacer(),

                Text(
                  'VALHALLA GYM',
                  style: TextStyle(
                    color: Color.fromRGBO(243, 243, 243, 1.0),
                    fontSize: 24,
                    fontFamily: 'Nordic chance',
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                Spacer(),
                // Notificacion de nuevo profe
                  if(isAdmin)
                  Badge(
                  isLabelVisible: _pendingUsersCount > 0,
                  label: Text(
                    '$_pendingUsersCount',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 10),
                  ),
                  backgroundColor: Colors.red,                    
                  child:  CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 246, 243, 230),
                      child: IconButton(
                      
                        //focusNode: _buttonFocusNode,
                        onPressed: () 
                        => _showPendingUserSheet(),
                        icon: Icon(
                          Icons.notifications,
                          color: Color.fromRGBO(44, 50, 50, 0.9),
                          size: 25,
                        ),
                        tooltip: 'Perfil',
                      ),
                    )
                  
                ),

                SizedBox(width: 16,),
                MenuAnchor(
                  childFocusNode: _buttonFocusNode,
                  menuChildren: <Widget>[
                    MenuItemButton(
                      leadingIcon: Icon(Icons.person, color: Colors.white70),
                      //onPressed: _navigateToPerfil,
                      child: Text(
                        'Perfil',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    Divider(color: Colors.white38, height: 1),
                    MenuItemButton(
                      leadingIcon: Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: _logout,
                      child: Text(
                        'Cerrar Sesion',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                  style: MenuStyle(
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      Color.fromRGBO(44, 50, 50, 0.9),
                    ),
                    elevation: WidgetStateProperty.all(8),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: IconButton(
                        //focusNode: _buttonFocusNode,
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },

                        icon: Icon(
                          Icons.person,
                          color: Color.fromRGBO(44, 50, 50, 0.9),
                          size: 25,
                        ),
                        tooltip: 'Perfil',
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDesktop) {
  final user = context.read<AuthProvider>().user;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 20 : 12,
      ),
      child: Text(
        //Ver la forma de ponerlo con el nombre del profesor solucion: usar el id para sacar el first_name
        'Bienvenido ${user?.name ?? 'Usuario'}',
        textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        style: TextStyle(
          color: Color.fromRGBO(243, 243, 243, 1.0),
          fontSize: isDesktop ? 42 : 28,
          fontFamily: 'inter',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDesktop, BoxConstraints constraints) {
        final log = Logger('DashboardScreen');
    return SizedBox(
      height: isDesktop ? 500 : 400,
      child: CalendarControllerProvider(
        controller: _eventController,
        child: Container(
          decoration: BoxDecoration(
            color: isDesktop
                ? Colors.amberAccent
                : Color.fromARGB(255, 17, 19, 24).withValues(colorSpace: ColorSpace.sRGB),

            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.black12, width: 0.5),
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: MonthView(
              showBorder: true,
              controller: _eventController,
              cellAspectRatio: isDesktop ? 1.4 : 1.3,
              showWeekends: true,
              initialMonth: DateTime.now(),
            //recuadro de los dias
              weekDayBuilder: (day) {
                final days = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
                return Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    days[day % 7],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, backgroundColor: Colors.white),
                  ),
                );
              },
              onEventTap: (events, date) {
                log.info('Evento en $date: $events');
              },
              headerBuilder: (date) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  color: Color.fromRGBO(44, 50, 50, 0.9),
                  alignment: Alignment.center,
                  child: Text(
                    '${_getMonthName(date.month)} ${date.year}',
                    style: TextStyle(
                      color: Color.fromRGBO(243, 243, 243, 1.0),
                      fontSize: 20,
                      fontFamily: 'inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F3).withValues(colorSpace: ColorSpace.sRGB),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y búsqueda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alumnos Activos',
                style: TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontSize: isDesktop ? 28 : 22,
                  fontFamily: 'inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isDesktop)
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: Color(0xFFF3F3F3).withValues(colorSpace: ColorSpace.sRGB),
                      ),
                      hintText: 'Buscar alumno...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFFF3F3F3).withValues(colorSpace: ColorSpace.sRGB),
                      ),
                      filled: true,
                      fillColor: Color.fromARGB(255, 122, 122, 122),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Búsqueda mobile
          if (!isDesktop) ...[
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(                
                hintText: 'Buscar alumno...',
                prefixIcon: Icon(Icons.search),
                filled: true,

                fillColor: Color.fromARGB(255, 122, 122, 122).withValues(colorSpace: ColorSpace.sRGB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          SizedBox(height: 16),

          // Lista de alumnos
          isDesktop ? _buildStudentsTable() : _buildStudentCards(),
        ],
      ),
    );
  }
//Listado dashboard principal 
  Widget _buildStudentsTable() {
    // Desktop: Tabla
    return Table(
      border: TableBorder.all(
        color: Color(0xFFC0C0C0),
        width: 0.5,
        borderRadius: BorderRadius.circular(8),
      ),

      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: Color(0xFF343434).withValues(colorSpace: ColorSpace.sRGB),
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _buildTableCell('Nombre', isHeader: true),
            _buildTableCell('Email', isHeader: false),
            _buildTableCell('Plan', isHeader: true),
            _buildTableCell('Estado', isHeader: false),
            _buildTableCell('Acciones', isHeader: false),
          ],
        ),
        // Datos de ejemplo
        _buildStudentRow('Juan Pérez', 'juan@email.com', 'Premium', 'Activo'),
        _buildStudentRow('María García', 'maria@email.com', 'Básico', 'Activo'),
        _buildStudentRow(
          'Carlos López',
          'carlos@email.com',
          'Premium',
          'Pendiente',
        ),
      ],
    );
  }

  TableRow _buildStudentRow(
    String name,
    String email,
    String plan,
    String status,
  ) {
    return TableRow(
      children: [
        _buildTableCell(name),
        _buildTableCell(email),
        _buildTableCell(plan),
        _buildTableCell(
          status,
          color: status == 'Activo' ? Colors.green : Colors.orange,
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF1B1B1B), size: 18),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Color(0xFF1B1B1B),
          fontSize: isHeader ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
//Cada card especifica del dashboard principal de cada cliente
  Widget _buildStudentCards() {
    // Mobile: Cards
    return Column(
      children: [
        _buildStudentCard('Juan Pérez', 'juan@email.com', 'Premium', 'Activo'),
        SizedBox(height: 12),
        _buildStudentCard(
          'María García',
          'maria@email.com',
          'Básico',
          'Activo',
        ),
        SizedBox(height: 12),
        _buildStudentCard(
          'Carlos López',
          'carlos@email.com',
          'Premium',
          'Pendiente',
        ),
      ],
    );
  }

  Widget _buildStudentCard(
    String name,
    String email,
    String plan,
    String status,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF3F3F3).withValues(colorSpace: ColorSpace.sRGB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: const Color(0xFF1B1B1B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Activo' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: Color(0xFF1B1B1B), fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(email, style: TextStyle(color: Colors.black54)),
          SizedBox(height: 4),
          Text(
            'Plan: $plan',
            style: TextStyle(color: const Color.fromARGB(255, 168, 184, 24)),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              //Editar alumno
              IconButton(
                icon: Icon(Icons.edit, color: Colors.black),
                onPressed: () {},
              ),
              //Eliminar
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildPendingUsersSheet(){
  return Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Solicitudes Pendientes',
      style: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold, 
      ),
      ),
      SizedBox(height: 16,),
      Expanded(child: _pendingUsers.isEmpty
      ? Center(
        child: Text('No hay solicitudes pendientes',
        style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    return _buildPendingUserCard(user);
                  },
                ),
        ),
      ],
    ),
  );
}
Widget _buildPendingUserCard(UserModel user){
  return Card(
    color: Colors.black,
    margin: EdgeInsets.only(bottom:12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text(
                user.name ?? 'Sin nombre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(user.email, style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.work, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(
                user.workArea?.value ?? 'Sin área',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.check),
                  label: Text('Aprobar'),
                  onPressed: () => _approveUser(user.id),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.close),
                  label: Text('Rechazar'),
                  onPressed: () => _rejectUser(user.id),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _approveUser(String userId) async {
  final result = await SupabaseService.approveUser(userId);
  if(result['success'] == true){
    Navigator.pop(context);
    await _loadPendingUsers();
  }
}
Future<void> _rejectUser(String userId) async {
  final result = await SupabaseService.rejectUser(userId);
  if(result['success'] == true){
    Navigator.pop(context);
    await _loadPendingUsers();
  }
}
  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}
