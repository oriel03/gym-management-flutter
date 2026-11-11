/// Modelo que mapea la vista `student_details` de Supabase
class StudentDetails {
  final int studentId;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? emergencyContact;
  final DateTime? dateOfBirth;
  final String? medicalConditions; 
  final String? bloodType;
  final bool studentActive;
  final DateTime studentCreatedAt;


  // Plan data
  final int? planId;
  final String? planName;
  final double? monthlyPrice;
  final int? daysPerWeek;
  final bool? isPersonalized;

  // Teacher data
  final String? teacherId;
  final String? teacherName;
  final String? workArea;

  // Active plan details
  final int? studentPlanId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? preferredShift;
  final String? routineUrl;
  final String? planNotes;
  final String? planStatus; // 'activo' | 'por_vencer' | 'vencido'

  // Last payment
  final String? lastPaymentStatus;
  final DateTime? lastPaymentDate;

  StudentDetails({
    required this.studentId,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.emergencyContact,
    this.dateOfBirth,
    this.medicalConditions,
    this.bloodType,
    required this.studentActive,
    required this.studentCreatedAt,
    this.planId,
    this.planName,
    this.monthlyPrice,
    this.daysPerWeek,
    this.isPersonalized,
    this.teacherId,
    this.teacherName,
    this.workArea,
    this.studentPlanId,
    this.startDate,
    this.endDate,
    this.preferredShift,
    this.routineUrl,
    this.planNotes,
    this.planStatus,
    this.lastPaymentStatus,
    this.lastPaymentDate,
  });

  bool get hasPlan => planId != null;
  bool get isPlanExpired => planStatus == 'vencido';
  bool get isPlanAboutToExpire => planStatus == 'por_vencer';

  factory StudentDetails.fromMap(Map<String, dynamic> map) {
    return StudentDetails(
      studentId: map['student_id'],
      fullName: map['full_name'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      emergencyContact: map['emergency_contact'],
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'])
          : null,
      medicalConditions: map['medical_conditions'],
      bloodType: map['blood_type'],
      studentActive: map['student_active'] ?? true,
      studentCreatedAt: DateTime.parse(map['student_created_at']),
      planId: map['plan_id'],
      planName: map['plan_name'],
      monthlyPrice: map['monthly_price'] != null
          ? (map['monthly_price'] as num).toDouble()
          : null,
      daysPerWeek: map['days_per_week'],
      isPersonalized: map['is_personalized'],
      teacherId: map['teacher_id'],
      teacherName: map['teacher_name'],
      workArea: map['work_area'],
      studentPlanId: map['student_plan_id'],
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'])
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'])
          : null,
      preferredShift: map['preferred_shift'],
      routineUrl: map['routine_url'],
      planNotes: map['plan_notes'],
      planStatus: map['plan_status'],
      lastPaymentStatus: map['last_payment_status'],
      lastPaymentDate: map['last_payment_date'] != null
          ? DateTime.parse(map['last_payment_date'])
          : null,
    );
  }
  //determinar edad 
  int? get age {
    if(dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;

    //resta del año si aun no cumplio
    if(today.month < dateOfBirth!.month || (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)){
      age--;
    }
    return age;
  }
}