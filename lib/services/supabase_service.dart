//Este archivo es para la comunicacion con la base de datos

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:gym_management_app/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';
import '../models/plan.dart';

/*
TENER EN CUENTA
Metodos Update/Delete -> Necesitan WHERE
Siempre manejar errores con try-catch
usar select con joins para obtener datos relacionados
*/

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

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
  static String _hashPin(String pin) {
    const salt =
        'your_app_salt_here'; // En producción, usar variables de entorno o un salt dinámico.
    var bytes = utf8.encode(pin + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /*============== R E G I S T E R -> Tabla users ===============*/
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String pin,
    required String workArea,
  }) async {
    try {
      final pinHash = _hashPin(pin);

      final userResponse = await _client
          .from('users')
          .insert({
            'name': name,
            'email': email,
            'username': username,
            'pin': pinHash,
            'work_area': workArea,
            'is_active': true,
          })
          .select()
          .single();
      return {'success': true, 'user': userResponse};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /*============== L O G I N  / R E G I S T E R ===============*/
  //Login de usuario(actualizando esquema)
  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String pin,
  }) async {
    try {
      final pinhash = _hashPin(pin);

      //buscar usuario
      final userResponse = await _client
          .from('users')
          .select('id, username, name, work_area, is_active')
          .eq('username', username)
          .eq('pin', pinhash)
          .eq('is_active', true)
          .maybeSingle();

      if (userResponse == null) {
        return {'success': false, 'error': 'Credenciales invalidas'};
      }
      return {'success': true, 'user': userResponse};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Obtener usuarios por área (útil para profesores)
  static Future<List<Map<String, dynamic>>> getUsersByArea(
    String workArea,
  ) async {
    try {
      final response = await _client
          .from('users')
          .select('id, name, username, work_area, created_at')
          .eq('work_area', workArea)
          .eq('is_active', true)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users by area: $e');
      return [];
    }
  }

  /*============== P A S S W O R D S ===============*/
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://gym-management-flutter.vercel.app/reset-password',
      );

      return {'success': true, 'message': 'Email de recuperacion enviado'};
    } on AuthException catch (e) {
      return {'success': false, 'Error': e.message};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado al enviar email'};
    }
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String newPin,
  }) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPin));
      return {'success': true, 'Message': 'Pin actualizado exitosamente'};
    } on AuthApiException catch (e) {
      return {'success': false, 'Error': e.message};
    } catch (e) {
      return {'success': false, 'error': 'Error al actualizar el PIN'};
    }
  }

  /*============== P L A N E S ===============*/
  //Obtener planes
  //response -> respuesta
  Future<List<Plan>> getPlans() async {
    try {
      final response = await SupabaseService.client.from('plans').select();

      return (response as List).map((plan) => Plan.fromJson(plan)).toList();
    } catch (e) {
      print('Error obteniendo planes: $e');
      //throw exception -> Lanzar excepcion
      throw Exception('No se pudieron cargar los planes');
    }
  }

  //Agregar plan
  Future<Map<String, dynamic>> addPlan(Plan plan) async {
    try {
      final response = await SupabaseService.client
          .from('plans')
          .insert(plan.toJson())
          .select()
          .single();

      return {'success': true, 'plan': Plan.fromJson(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error agregando plan: ${e.toString()}',
      };
    }
  }
  /*============== E S T U D I A N T E S ==================== */

  //obtener Todos los Estudiantes (Para admin)
  Future<List<Student>> getAllStudents() async {
    try {
      final response = await SupabaseService.client.from('students').select('''
        *,
        users!students_profesor_id_fkey(
        id, name, email, work_area),
        plans(
        id, name, monthly_price)
      ''');
      return (response as List)
          .map((student) => Student.fromJson(student))
          .toList();
    } catch (e) {
      print('Error obtenido todos los estudiantes: $e');
      throw Exception('No se pudieron cargar los estudiantes');
    }
  }

  //Obtener estudiantes por profesor especifico
  Future<List<Student>> getStudentsByProfesor(String profesorId) async {
    try {
      // Se corrigió el error de sintaxis del ')'
      final response = await SupabaseService.client
          .from('students')
          .select('''
          *,
          //Busca los estudiantes que coinciden con el id del profesor, obteniendo los datos y en que area trabaja
          users!students_profesor_id_fkey(
          id, name, email, work_area),
          plans(
          id, name, monthly_price)
          ''')
          .eq('profesor_id', profesorId);

      return (response as List)
          .map((student) => Student.fromJson(student))
          .toList();
    } catch (e) {
      print('Error obteniendo estudiantes de profesor $e');
      throw Exception('No se pudieron cargar los estudiantes del profesor ');
    }
  }

  //obtener estudiantes especificos
  Future<List<Student>> getStudents() async {
    try {
      // Se corrigió el error de sintaxis del ')'
      final response = await SupabaseService.client.from('Students').select('''
          *,
          users!students_profesor_id_fkey(
          id, name, email, work_area),
          plans(
          id, name, monthly_price)
          ''');

      return (response as List)
          .map((student) => Student.fromJson(student))
          .toList();
    } catch (e) {
      print('Error obteniendo estudiantes $e');
      throw Exception('No se pudieron cargar los estudiantes ');
    }
  }

  // Obtener estudiante por ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final response = await SupabaseService.client
          .from('students')
          .select('''
          *,
          users!students_profesor_id_fkey (
            id, name, email, work_area
          ),
          plans (
            id, name, monthly_price
          )
        ''')
          .eq('id', studentId)
          .single();

      return Student.fromJson(response);
    } catch (e) {
      print('Error obteniendo estudiante: $e');
      return null;
    }
  }

  //Agregar estudiantes
  Future<Map<String, dynamic>> addStudent(Student student) async {
    try {
      final response = await SupabaseService.client
          .from('students')
          .insert(student.toJson())
          .select('''
          *,
          users!students_profesor_id_fkey(
          id, name, email, work_area
          ),
          plans(
          id, name, monthly_price
          )
          ''')
          .single();

      return {'success': true, 'student': Student.fromJson(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error agregando estudiante: ${e.toString()}',
      };
    }
  }

  //Modificar estudiantes -> M
  Future<Map<String, dynamic>> updateStudent(Student student) async {
    try {
      // Se corrigió el nombre de la tabla de 'student' a 'students'
      // Se corrigió la sintaxis del select
      final response = await SupabaseService.client
          .from('students')
          .update(student.toJson())
          .eq('id', student.id)
          .select('''
          *,
          users!students_profesor_id_fkey(
          id, name, email, work_area
          ),
          plans(
          id,name, monthly_price
          )
          ''')
          .single();
      return {'success': true, 'Student': Student.fromJson(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error Actualizado estudiante: ${e.toString()}',
      };
    }
  }

  //Eliminar estudiante
  //-> Necesitan WHERE, -> NO usan tojson()
  Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    try {
      await SupabaseService.client
          .from('students')
          .delete()
          .eq('id', studentId);

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error eliminado estudiante: ${e.toString()}',
      };
    }
  }

  //Actualizacion de pago
  Future<Map<String, dynamic>> updatePaymentStatus(
    Student student,
    String status,
  ) async {
    try {
      // Se corrigió el .eq para que use student.id
      final response = await SupabaseService.client
          .from('students')
          .update({'payment_status': status})
          .eq('id', student.id)
          .select()
          .single();

      return {'success': true, 'student': Student.fromJson(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al actualizar el pago ${e.toString()}',
      };
    }
  }

  // ==================== USUARIOS/PROFESORES ====================

  // Obtener todos los profesores
  Future<Map<String, dynamic>> getAllProfesores() async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('is_active', true); //pregunta si son usuarios activos
      //convierte la lista de respuestas
      final profesores = (response as List)
          .map((profesor) => UserModel.fromJson(profesor))
          .toList();

      return {'success': true, 'profesor': profesores};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al actualizar el pago ${e.toString()}',
      };
    }
  }

  // Obtener perfil de un profesor
  Future<Map<String, dynamic>> getProfesorById(String profesorId) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('id', profesorId)
          .single();

      return {'success': true, 'profesor': UserModel.fromJson(response)};
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo profesor: ${e.toString()}',
      };
    }
  }

  // ==================== ESTADÍSTICAS ====================
  // Obtener estadísticas de estudiantes por profesor

  Future<Map<String, dynamic>> getEstadisticasByProfesor(
    String profesorId,
  ) async {
    try {
      //Obtiene todos los estudiantes de ese profesor
      final students = await getStudentsByProfesor(profesorId);

      return {
        'total_estudiantes': students.length,
        'pagados': students.where((s) => s.isPaid).length,
        'vencidos': students.where((s) => s.isOverdue).length,
      };
    } catch (e) {
      print('Error obteniendo las caracteristicas: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getEstadisticasCompletas(
    String profesorId,
  ) async {
    try {
      final students = await getStudentsByProfesor(profesorId);

      double ingresosPagados = 0;
      double ingresosPendientes = 0;

      for (final student in students) {
        if (student.hasPlan) {
          if (student.isPaid) {
            // Se corrigió la lógica para sumar los ingresos pagados
            ingresosPagados += student.monthlyPrice;
          } else if (student.isPending) {
            ingresosPendientes += student.monthlyPrice;
          }
        }
      }
      return {
        'total_estudiantes': students.length,
        'pagados': students.where((s) => s.isPaid).length,
        'pendientes': students.where((s) => s.isPending).length,
        'vencidos': students.where((s) => s.isOverdue).length,
        'ingresos_pagados': ingresosPagados,
        'ingresos_pendientes': ingresosPendientes,
        'ingresos_totales': ingresosPagados + ingresosPendientes,
      };
    } catch (e) {
      print('Error obteniendo estadisticas completas: $e');
      return {};
    }
  }

  // ==================== BÚSQUEDAS Y FILTROS ====================

  // Buscar estudiantes por nombre
  Future<Map<String, dynamic>> buscarNombreEstudiante(String name) async {
    try {
      // Se agregó 'await' para esperar la respuesta de Supabase
      // Se agregó `.ilike` para una búsqueda flexible que no distinga entre mayúsculas y minúsculas
      final response = await SupabaseService.client
          .from('Students')
          .select('*')
          .ilike('name', '%$name%');

      final List<Student> students = (response as List)
          .map((json) => Student.fromJson(json))
          .toList();

      if (students.isEmpty) {
        return {
          'success': false,
          'error': 'No se encontraron estudiantes con ese nombre',
        };
      }
      return {
        'success': true,
        'students': students,
        'count': students.length, //Cuantos se encontraron
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al buscar estudiantes: ${e.toString()}',
      };
    }
  }
}
