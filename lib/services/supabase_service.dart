//Este archivo es para la comunicacion con la base de datos

import 'package:gym_management_app/models/student_details.dart';
import 'package:gym_management_app/models/user.dart';
//import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan.dart';
import '../models/payment.dart';
import '../models/student_plan.dart';
import 'package:logging/logging.dart';
/*
TENER EN CUENTA
Metodos Update/Delete -> Necesitan WHERE
Siempre manejar errores con try-catch
usar select con joins para obtener datos relacionados
Todos los metodos son static
nomeclatura: fromMap/toInsertMap/toUpdateMap en todos los modelos
- las consultas de estudiante se hacen siempre via la vista students_details
*/

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final log = Logger('SupabaseService');
  static SupabaseClient get client => _client;

  //Inicializar Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  // Se corrige la gestión del salt.
  // Es mejor usar un salt único por usuario, pero para este ejemplo,
  // se hace la función privada y el salt se mantiene como constante.


  /*============== AUTH ===============*/
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String pin,
    required String workArea,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email.toLowerCase().trim(),
        password: pin,
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        return {'success': false, 'error': 'No se puede crear la cuenta'};
      }
      // Pequeño margen para asegurar que la sesión esté completamente adjuntada
      await Future.delayed(const Duration(milliseconds: 300));
      
      final userResponse = await _client
          .from('users')
          .insert({
            'id': authUser.id,
            'name': name.trim(),
            // En minúsculas: el login busca el username con toLowerCase().
            // Si alguien se registraba como "Juan", después no podía entrar.
            'email': email.toLowerCase().trim(),
            'username': username.toLowerCase().trim(),
            'work_area': workArea,
            'is_active': false,
            'status': 'pendiente',
          })
          .select()
          .single();

      return {'success': true, 'user': userResponse};
    } on AuthException catch (e) {
      log.warning('Error de auth en registerUser', e);
      return {'success': false, 'error': e.message};
    } catch (e, stackTrace) {
      log.severe('Error en registerUser', e, stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> logoutUser() async {
    await _client.auth.signOut();
  }

  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String pin,
  }) async {
    try {
      final emailResponse = await _client.rpc(
        'get_email_by_username',
        params: {'p_username': username.toLowerCase().trim()},
      );

      if(emailResponse == null){
        return {'success': false, 'error': 'Credenciales invalidas'};
      }

      final authResponse = await _client.auth.signInWithPassword(
        email: emailResponse as String,
        password: pin,
      );

      final authUser =authResponse.user;
      if (authUser == null) {
        return {'success': false, 'error': 'Credenciales invalidas'};
      }

      final userResponse = await _client
          .from('users')
          .select(
            'id, username, name, work_area, is_active, created_at, updated_at',)
          .eq('id', authUser.id)
          .maybeSingle();

      if (userResponse == null) {
        return {'success': false, 'error': 'perfil no encontrado'};
      }
      if (userResponse['is_active'] != true) {
        return {'success': false, 'error': 'Tu cuenta esta inactiva'};
      }
      return {'success': true, 'user': userResponse};
    } on AuthException catch (e) {
      log.warning('Error de auth en loginUser', e);
      return {'success': false, 'error': 'Credenciales invalidas'};
    } catch (e, stackTrace) {
      log.severe('Error en el loginUser', e, stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ===================== U S U A R I O S =====================

  // Obtener usuarios por área (útil para profesores)
  static Future<List<Map<String, dynamic>>> getUsersByArea(
    String workArea,
  ) async {
    try {
      final response = await _client
          .from('users')
          .select('id, name, username, work_area, created_at, updated_at')
          .eq('work_area', workArea)
          .eq('is_active', true)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      log.warning('Error fetching users by area', e, stackTrace);
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAllProfesores() async {
    try {
      final response = await _client
          .from('users')
          .select(
            'id, name, username, work_area, is_active, created_at, updated_at',
          )
          .eq('is_active', true)
          .order('name');

      final profesores = (response as List)
          .map((u) => UserModel.fromMap(u)) //MODIFICAR TIPO DE USER MODEL
          .toList();

      return {'success': true, 'profesores': profesores};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo profesores: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getProfesorById(
    String profesorId,
  ) async {
    try {
      final response = await _client
          .from('users')
          .select(
            'id, name, username, email, work_area, is_active, created_at, updated_at',
          )
          .eq('id', profesorId)
          .single();

      return {'success': true, 'profesor': UserModel.fromMap(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo profesor: ${e.toString()}',
      };
    }
  }

  /*============== P L A N E S ===============*/
  //Obtener planes
  //response -> respuesta
  static Future<List<Plan>> getPlans() async {
    try {
      final response = await _client
          .from('plans')
          .select()
          .order('days_per_week');

      return (response as List).map((p) => Plan.fromMap(p)).toList();
    } catch (e) {
      log.warning('Error obteniendo planes: $e');
      //throw exception -> Lanzar excepcion
      throw Exception('No se pudieron cargar los planes');
    }
  }

  static Future<Map<String, dynamic>> updatePlan(Plan plan) async {
    try {
      final response = await _client
          .from('plans')
          .update(plan.toUpdateMap())
          .eq('id', plan.id)
          .select()
          .single();

      return {'success': true, 'plan': Plan.fromMap(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizando plan: ${e.toString()}',
      };
    }
  }

  //Agregar plan
  static Future<Map<String, dynamic>> addPlan(Plan plan) async {
    try {
      final response = await _client
          .from('plans')
          .insert(plan.toInsertMap())
          .select()
          .single();

      return {'success': true, 'plan': Plan.fromMap(response)};
    } catch (e, stackTrace) {
      log.severe('Error en addPlan', e, stackTrace);
      return {
        'success': false,
        'error': 'Error agregando plan: ${e.toString()}',
      };
    }
  }

  /*============== N U E V O S   U S U A R I O S         A C E P T A R ====================*/
  static Future<List<UserModel>> getPendingUsers() async {
    try {
      final response = await _client
          .from('users')
          .select(
            'id, name, email, work_area, created_at, updated_at, is_active, username',
          )
          .eq('status', 'pendiente')
          .order('created_at', ascending: false);

      return (response as List).map((u) => UserModel.fromMap(u)).toList();
    } catch (e, stackTrace) {
      log.severe('Error obteniendo usuarios pendientes', e, stackTrace);
      return [];
    }
  }

  // El login exige is_active = true, así que aprobar tiene que cambiar
  // las DOS columnas. Antes solo cambiaba status y el usuario aprobado
  // seguía sin poder entrar.
  // .select() devuelve las filas afectadas: si RLS bloquea el update
  // (quien aprueba no es admin), vuelve vacío en vez de dar error.
  static Future<Map<String, dynamic>> approveUser(String userId) async {
    try {
      final rows = await _client
          .from('users')
          .update({'status': 'activo', 'is_active': true})
          .eq('id', userId)
          .select('id');
      if ((rows as List).isEmpty) {
        return {'success': false, 'error': 'No tenés permiso para aprobar usuarios'};
      }
      return {'success': true};
    } catch (e, st) {
      log.warning('approveUser falló', e, st);
      return {'success': false, 'error': 'No se pudo aprobar el usuario'};
    }
  }

  static Future<Map<String, dynamic>> rejectUser(String userId) async {
    try {
      final rows = await _client
          .from('users')
          .update({'status': 'inactivo', 'is_active': false})
          .eq('id', userId)
          .select('id');
      if ((rows as List).isEmpty) {
        return {'success': false, 'error': 'No tenés permiso para rechazar usuarios'};
      }
      return {'success': true};
    } catch (e, st) {
      log.warning('rejectUser falló', e, st);
      return {'success': false, 'error': 'No se pudo rechazar el usuario'};
    }
  }

  /*============== D E T A L L E S          E S T U D I A N T E S ====================*/
  //Todas las consultas de estudiantes van por la vista students_details

  //obtener Todos los Estudiantes (Para admin)
  static Future<List<StudentDetails>> getAllStudents({
    bool? activeOnly,
  }) async {
    try {
      var query = _client.from('students_details').select();
      if (activeOnly == true) {
        query = query.eq('student_active', true);
      }
      final response = await query.order('full_name');
      log.info('RAW RESPONSE: $response');
      return (response as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();
    } catch (e) {
      log.warning('Error obtenido estudiantes',);
      throw Exception('No se pudieron cargar los estudiantes: $e');
    }
  }

  //Obtener estudiantes por profesor especifico
  static Future<List<StudentDetails>> getStudentsByProfesor(
    String profesorId, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _client
          .from('students_details')
          .select()
          .eq('teacher_id', profesorId);

      if (activeOnly) {
        query = query.eq('student_active', true);
      }
      final response = await query.order('full_name');
      return (response as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();
    } catch (e) {
      log.warning('Error obteniendo estudiantes de profesor $e');
      throw Exception('No se pudieron cargar los estudiantes del profesor ');
    }
  }

  // Obtener estudiante por ID
  static Future<StudentDetails?> getStudentById(int studentId) async {
    try {
      final response = await _client
          .from('students_details')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();

      return response != null ? StudentDetails.fromMap(response) : null;
    } catch (e) {
      log.warning('Error obteniendo estudiante: $e');
      return null;
    }
  }

  static Future<List<StudentDetails>> buscarEstudiantePorNombre(
    String name,
  ) async {
    try {
      final response = await _client
          .from('students_details')
          .select()
          .ilike('full_name', '%$name%')
          .order('full_name');
      return (response as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();
    } catch (e) {
      log.warning('Error buscando estudiante: $e');
      return [];
    }
  }

  // Alta de alumno + plan en UNA llamada a la función SQL
  // create_student_with_plan. Antes eran dos inserts sueltos:
  //  - si el segundo fallaba, quedaba un alumno sin plan (huérfano);
  //  - un profesor no podía leer el alumno recién creado (RLS solo le
  //    muestra alumnos con un plan suyo), así que el insert().select() fallaba.
  // profesorId == null => la base usa al usuario logueado.
  static Future<Map<String, dynamic>> createStudentWithPlan({
    required Map<String, dynamic> student,
    int? planId,
    String? profesorId,
    String preferredShift = 'mañana',
  }) async {
    try {
      final id = await _client.rpc(
        'create_student_with_plan',
        params: {
          'p_student': student,
          'p_plan_id': planId,
          'p_profesor_id': profesorId,
          'p_preferred_shift': preferredShift,
        },
      );
      return {'success': true, 'student_id': id as int};
    } on PostgrestException catch (e, st) {
      log.warning('create_student_with_plan falló code=${e.code}', e, st);
      // 23505 = valor duplicado (email o DNI ya cargados)
      final msg = e.code == '23505'
          ? 'Ya existe un alumno con ese email o DNI'
          : e.code == '42501'
              ? 'No tenés permiso para crear alumnos'
              : 'No se pudo crear el alumno';
      return {'success': false, 'error': msg};
    } catch (e, st) {
      log.severe('Error inesperado creando alumno', e, st);
      return {'success': false, 'error': 'No se pudo crear el alumno. Revisá tu conexión.'};
    }
  }

  // Modificar alumno. .select('id') devuelve las filas cambiadas: si RLS
  // no deja editar (no es tu alumno), vuelve vacío en vez de dar error,
  // y antes la app mostraba "guardado" aunque no se hubiera guardado nada.
  static Future<Map<String, dynamic>> updateStudent(
    int studentId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final rows = await _client
          .from('students')
          .update(fields)
          .eq('id', studentId)
          .select('id');
      if ((rows as List).isEmpty) {
        return {'success': false, 'error': 'No tenés permiso para editar este alumno'};
      }
      final detail = await getStudentById(studentId);
      return {'success': true, 'student': detail};
    } on PostgrestException catch (e, st) {
      log.warning('updateStudent falló code=${e.code}', e, st);
      final msg = e.code == '23505'
          ? 'Ya existe un alumno con ese email o DNI'
          : 'No se pudo guardar el alumno';
      return {'success': false, 'error': msg};
    } catch (e, st) {
      log.severe('Error inesperado editando alumno', e, st);
      return {'success': false, 'error': 'No se pudo guardar. Revisá tu conexión.'};
    }
  }

  //desactivar estudiante NO eliminar es cambiando un bool es increible que se me haya pasado
  static Future<Map<String, dynamic>> desactivateStudent(
    int studentId,
  ) async {
    try {
      await _client
          .from('students')
          .update({'is_active': false})
          .eq('id', studentId);

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error desactivando estudiante: ${e.toString()}',
      };
    }
  }

  // ====================    STUDENT PLANS    ====================
  static Future<Map<String, dynamic>> assignPlan(StudentPlan plan) async {
    try {
      //desactivar plan anterior si existe
      await _client
          .from('student_plans')
          .update({'is_active': false})
          .eq('student_id', plan.studentId)
          .eq('is_active', true);

      final response = await _client
          .from('student_plans')
          .insert(plan.toInsertMap())
          .select()
          .single();

      return {
        'success': true,
        'student_plan': StudentPlan.fromMap(response),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error asignado plan: ${e.toString()}',
      };
    }
  }

  static Future<List<StudentPlan>> getPlanHistoryByStudent(
    int studentId,
  ) async {
    try {
      final response = await _client
          .from('student_plans')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => StudentPlan.fromMap(e)).toList();
    } catch (e) {
      log.warning('Error obteniendo historial de planes: $e');
      return [];
    }
  }

  /*   ====================       PAGOS         ==================== */
  //registrar pago
  static Future<Map<String, dynamic>> registerPayment(Payment payment) async {
    try {
      final response = await _client
          .from('payments')
          .insert(payment.toInsertMap())
          .select()
          .single();

      return {'success': true, 'payment': Payment.fromMap(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error registrando pago: ${e.toString()}',
      };
    }
  }

  //Total de pagos
  static Future<Map<String, dynamic>> getAllPayment() async {
    try {
      final response = await _client
          .from('payments')
          // Todas las columnas: Payment.fromMap necesita due_date,
          // created_at y updated_at. Con la lista recortada que había,
          // DateTime.parse(null) rompía la lectura de cualquier pago.
          .select()
          .eq('payment_status', 'pago')
          .order('id', ascending: false);

      final payments = (response as List)
          .map((e) => Payment.fromMap(e))
          .toList();

      return {'success': true, 'payments': payments};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo pagos: ${e.toString()}',
      };
    }
  }

  //obtener los pagos de un estudiante
  static Future<List<Payment>> getPaymentStudent(int studentId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('student_id', studentId)
          .order('payment_date', ascending: false);

      return (response as List).map((e) => Payment.fromMap(e)).toList();
    } catch (e) {
      log.warning('Error obteniendo pagos del estudiante: $e');
      return [];
    }
  }

  //obtener pagos por periodo
  static Future<List<Payment>> getPaymentByPeriod(int year, int month) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('period_year', year)
          .eq('period_month', month)
          .order('payment_date', ascending: false);

      return (response as List).map((e) => Payment.fromMap(e)).toList();
    } catch (e) {
      log.warning('Error obtener pagos por periodo: $e');
      return [];
    }
  }

  //actualizar pagos
  static Future<Map<String, dynamic>> updatePaymentStatus(
    int paymentId,
    PaymentStatus status, {
    PaymentMethod? method,
    String? reference,
  }) async {
    try {
      final fields = {
        'payment_status': status.value,
        if (method != null) 'payment_method': method.value,
        if (reference != null) 'transaction_reference': reference,
      };
      final response = await _client
          .from('payments')
          .update(fields)
          .eq('id', paymentId)
          .select()
          .single();

      return {'success': true, 'payment': Payment.fromMap(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error actualizado pago: ${e.toString()}',
      };
    }
  }

  // ==================== ESTADÍSTICAS ====================

  //TODAS VIA STUDENTS_DETAILS - UN SOLO FETCH, CALCULO EN DART

  static Future<Map<String, dynamic>> getEstadisticasCompletas({
    bool activeOnly = true,
  }) async {
    try {
      var query = _client.from('students_details').select();
      if (activeOnly) query = query.eq('student_active', true);
      final data = await query;

      final students = (data as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();

      double ingresosPagados = 0;
      double ingresosPendientes = 0;
      double ingresosAdeuda = 0;

      for (final s in students) {
        final precio = s.monthlyPrice ?? 0.0;
        switch (s.lastPaymentStatus) {
          case 'pago':
            ingresosPagados += precio;
            break;
          case 'pendiente':
            ingresosPendientes += precio;
            break;
          case 'adeuda':
            ingresosAdeuda += precio;
            break;
        }
      }

      return {
        'total_estudiantes': students.length,
        'pagados': students.where((s) => s.lastPaymentStatus == 'pago').length,
        'pendientes': students
            .where((s) => s.lastPaymentStatus == 'pendiente')
            .length,
        'adeuda': students.where((s) => s.lastPaymentStatus == 'adeuda').length,
        'sin_pago': students.where((s) => s.lastPaymentStatus == null).length,
        'plan_activo': students.where((s) => s.planStatus == 'activo').length,
        'plan_vencido': students.where((s) => s.isPlanExpired).length,
        'sin_plan': students.where((s) => !s.hasPlan).length,
        'ingresos_pagados': ingresosPagados,
        'ingresos_pendientes': ingresosPendientes,
        'ingresos_adeuda': ingresosAdeuda,
        'ingresos_totales':
            ingresosPagados + ingresosPendientes + ingresosAdeuda,
      };
    } catch (e) {
      log.warning('Error obtenido estadisticas: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getEstadisticasByProfesor(
    String profesorID,
  ) async {
    try {
      final students = await getStudentsByProfesor(
        profesorID,
        activeOnly: true,
      );

      double ingresosPagados = 0;
      double ingresosPendientes = 0;

      for (final s in students) {
        final precio = s.monthlyPrice ?? 0.0;
        if (s.lastPaymentStatus == 'pago') {
          ingresosPagados += precio;
        } else if (s.lastPaymentStatus == 'pendiente') {
          ingresosPendientes += precio;
        }
      }

      return {
        'total_estudiantes': students.length,
        'pagados': students.where((s) => s.lastPaymentStatus == 'pago').length,
        'pendientes': students
            .where((s) => s.lastPaymentStatus == 'pendiente')
            .length,
        'adeuda': students.where((s) => s.lastPaymentStatus == 'adeuda').length,
        'sin_pago': students.where((s) => s.lastPaymentStatus == null).length,
        'plan_activo': students.where((s) => s.planStatus == 'activo').length,
        'plan_vencido': students.where((s) => s.isPlanExpired).length,
        'sin_plan': students.where((s) => !s.hasPlan).length,
        'ingresos_pagados': ingresosPagados,
        'ingresos_pendientes': ingresosPendientes,
      };
    } catch (e) {
      log.warning('Error obtenido estadisticas: $e');
      return {};
    }
  }

  //helpers rapidos
  static Future<List<StudentDetails>> getStudentsWithPendingPayments() async {
    try {
      final response = await _client
          .from('students_details')
          .select()
          .inFilter('last_payment_status', ['pendiente', 'adeuda'])
          .eq('student_active', true)
          .order('full_name');

      return (response as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();
    } catch (e) {
      log.warning('Error obteniendo los estudiantes con pagos pendientes: $e');
      return [];
    }
  }

  static Future<List<StudentDetails>> getStudentsWithExpiringPlans() async {
    try {
      final response = await _client
          .from('students_details')
          .select()
          .eq('plan_status', 'por_vencer')
          .eq('student_active', true)
          .order('end_date');

      return (response as List)
          .map((e) => StudentDetails.fromMap(e))
          .toList();
    } catch (e) {
      log.warning('Error obteniendo estudiantes con planes por vencer: $e');
      return [];
    }
  }
}