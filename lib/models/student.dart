import 'package:gym_management_app/models/plan.dart';
import 'package:gym_management_app/models/user.dart';
import 'package:flutter/material.dart';

class Student {
  //Identificacion
  final String id;
  final String name;
  final String lastName;
  final String email;
  final String? phone;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? dni;
  final DateTime? dateOfBirth;
  final String schedule; //horario de clases

  //plan y horarios

  final String? planId; //ID del plan contratado
  final DateTime? planStartDate; //Fecha de inicio del plan
  final DateTime? planEndDate; //Fecha de fin del plan
  final String paymentStatus; //Estado de pago (Pagado, Pendiente, No pago)
  final String? routineUrl;
  final DateTime? lastPaymentDate; //Fecha del ultimo pago
  final DateTime? nextPaymentDate; //Fecha del proximo pago
  final double? monthPrice; //Numero de la cuota mensual
  final double? debt; //Deuda acumulada
  final String? notes; //Notas adicionales
  final DateTime createdAt; //Fecha de creacion del alumno

  final String profesorId;

  // Salud y condicion fisica
  final String? medicalConditions; //Condiciones medicas
  final String? fitnessGoals; //Objetivos de fitness

  // Sistema
  final bool isActive; //Si el estudiante esta activo o dado de baja

  final UserModel? profesor;
  final Plan? plan;

  Student({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    this.phone,
    this.emergencyContact,
    this.emergencyPhone,
    this.dni,
    this.dateOfBirth,
    required this.schedule,

    this.planId,
    this.planStartDate,
    this.planEndDate,
    required this.paymentStatus,
    this.routineUrl,
    this.lastPaymentDate,
    this.nextPaymentDate,
    this.monthPrice,
    this.debt = 0.0,
    this.notes,
    required this.createdAt,

    required this.profesorId,
    this.medicalConditions,
    this.fitnessGoals,

    this.isActive = true,
    this.profesor,
    this.plan,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      emergencyContact: json['emergency_contact'],
      emergencyPhone: json['emergency_phone'],
      dni: json['dni'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      schedule: json['schedule'],
      monthPrice: json['month_price'] != null
          ? (json['month_price'] as num).toDouble()
          : null,
      planId: json['plan_id'],
      planStartDate: json['plan_start_date'] != null
          ? DateTime.parse(json['plan_start_date'])
          : null,
      planEndDate: json['plan_end_date'] != null
          ? DateTime.parse(json['plan_end_date'])
          : null,
      paymentStatus: json['payment_status'],
      routineUrl: json['routine_url'],
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'])
          : null,
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.parse(json['next_payment_date'])
          : null,

      debt: json['debt']?.toDouble() ?? 0.0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),

      profesorId: json['profesor_id'],
      medicalConditions: json['medical_conditions'],
      fitnessGoals: json['fitness_goals'],

      isActive: json['is_active'] ?? true,
      profesor: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      plan: json['plans'] != null ? Plan.fromJson(json['plans']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'dni': dni,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'schedule': schedule,
      'month_price': monthPrice,
      'plan_id': planId,
      'plan_start_date': planStartDate?.toIso8601String(),
      'plan_end_date': planEndDate?.toIso8601String(),
      'payment_status': paymentStatus,
      'routine_url': routineUrl,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'next_payment_date': nextPaymentDate?.toIso8601String(),

      'debt': debt,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),

      'profesor_id': profesorId,
      'medical_conditions': medicalConditions,
      'fitness_goals': fitnessGoals,

      'is_active': isActive,
    };
  }

  Student copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? phone,
    String? emergencyContact,
    String? emergencyPhone,
    String? dni,
    DateTime? dateOfBirth,
    String? schedule,
    double? monthPrice,
    String? classType,

    String? planId,
    DateTime? planStartDate,
    DateTime? planEndDate,
    String? paymentStatus,
    String? routineUrl,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    double? monthlyFee,
    double? debt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profesorId,
    String? medicalConditions,

    String? fitnessGoals,
    DateTime? lastAttendanceDate,
    int? totalAttendances,
    bool? isActive,
    Plan? plan,
    UserModel? profesor,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      dni: dni ?? this.dni,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      schedule: schedule ?? this.schedule,
      planId: planId ?? this.planId,
      planStartDate: planStartDate ?? this.planStartDate,
      planEndDate: planEndDate ?? this.planEndDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      routineUrl: routineUrl ?? this.routineUrl,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      monthPrice: monthPrice ?? this.monthPrice,
      debt: debt ?? this.debt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,

      profesorId: profesorId ?? this.profesorId,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,

      isActive: isActive ?? this.isActive,
      profesor: profesor ?? this.profesor,
      plan: plan ?? this.plan,
    );
  }

  // ------ Metodos de conveniencia -----------

  // Nombre completo
  String get fullName => '$name $lastName';

  // Edad calculada
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Información del plan
  double get monthlyPrice =>
      plan?.monthlyPrice ?? 0.0; //Obtiene el precio mensual del plan

  String get planName => plan?.name ?? 'Sin plan'; //Obtiene el nombre del plan

  bool get hasPlan =>
      plan != null || planId != null; //Verifica si tiene plan asignado

  // Metodos de estado de pago
  bool get isPaid =>
      paymentStatus.toLowerCase() == 'pagado'; //Determina si esta pago

  bool get isPending =>
      paymentStatus.toLowerCase() == 'pendiente'; //Determina si esta pendiente

  bool get isOverdue =>
      paymentStatus.toLowerCase() == 'no pago'; //Determina si no esta pago

  bool get hasDebt => (debt ?? 0.0) > 0; //Verifica si tiene deuda

  // Estado del plan
  bool get isPlanExpired {
    if (planEndDate == null) return false;
    return DateTime.now().isAfter(planEndDate!);
  }

  int? get daysRemainingInPlan {
    if (planEndDate == null) return null;
    final difference = planEndDate!.difference(DateTime.now());
    return difference.inDays;
  }

  bool get isPlanExpiringSoon {
    final daysRemaining = daysRemainingInPlan;
    if (daysRemaining == null) return false;
    return daysRemaining <= 7 && daysRemaining > 0;
  }

  // Estado general
  String get statusSummary {
    if (!isActive) return 'Inactivo';
    if (isPlanExpired) return 'Plan vencido';
    if (hasDebt) return 'Con deuda';
    if (isPaid) return 'Activo';
    return 'Pendiente';
  }

  // Color según estado (útil para UI)
  Color get statusColor {
    if (!isActive) return Colors.grey;
    if (isPlanExpired || isOverdue) return Colors.red;
    if (isPlanExpiringSoon || hasDebt) return Colors.orange;
    if (isPaid) return Colors.green;
    return Colors.blue;
  }
}
