enum ShiftType {manana, tarde, noche}

extension ShiftTypeExtension on ShiftType{
  String get value{
    switch(this){
      case ShiftType.manana:
      return 'mañana';
      case ShiftType.tarde:
      return 'tarde';
      case ShiftType.noche:
      return 'noche';
    }
  }

  static ShiftType fromString(String value){
    switch (value) {
      case 'mañana':
      return ShiftType.manana;
      case 'tarde': 
      return ShiftType.tarde;
      case 'noche':
      return ShiftType.noche;
      default:
      return ShiftType.manana;
    }
  }
}

class StudentPlan{
  final String id;
  final String studentId;
  final String userId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final ShiftType preferredShift;
  final String? routineUrl;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;


//No deberia ser userId en vez de profesorId?
  StudentPlan({
    required this.id,
    required this.studentId,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.preferredShift,
    this.routineUrl,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
});

  factory StudentPlan.fromMap(Map<String, dynamic> map) {
   return StudentPlan(
      id: map['id'],
      studentId: map['student_id'],
      planId: map['plan_id'],
      userId: map['profesor_id'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      preferredShift: ShiftTypeExtension.fromString(
          map['preferred_shift'] ?? 'mañana'),
      routineUrl: map['routine_url'],
      notes: map['notes'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'student_id': studentId,
      'plan_id': planId,
      'profesor_id': userId,
      'start_date': startDate.toIso8601String().split('T').first,
     'end_date': endDate.toIso8601String().split('T').first,
      'preferred_shift': preferredShift.value,
      'routine_url': routineUrl,
      'notes': notes,
      'is_active': isActive,
    };
  }
}