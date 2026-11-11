
class Student {
  //Identificacion
  final int id;
  final String dni;
  final int planId;
  final String name;
  final String lastName;
  final String email;
  final String? phone;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime? dateOfBirth;
  final String? medicalConditions;
  final String? bloodType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;


Student({
  required this.id,
  required this.dni,
  required this.planId,
  required this.name,
  required this.lastName,
  required this.email,
  this.phone,
  this.emergencyContact,
  this.emergencyPhone,
  this.dateOfBirth,
  this.medicalConditions,
  this.bloodType,
  required this.isActive,
  required this.createdAt,
  required this.updatedAt,

});

  String get fullName => '$name $lastName';


  
  factory Student.fromMap(Map<String, dynamic> map) {
    final studentData = map['students'] as Map<String, dynamic>;
    return Student(
      id: studentData['id'],
      name: studentData['name'],
      dni: studentData['dni'],
      planId: studentData['plan_id'],
      lastName: studentData['last_name'], 
      email: studentData['email'],
      phone: studentData['phone'],
      emergencyContact: studentData['emergency_contact'],
      emergencyPhone: studentData['emergency_phone'],
      dateOfBirth: studentData['date_of_birth'] != null
          ? DateTime.parse(studentData['date_of_birth'])
          : null,
      medicalConditions: studentData['medical_conditions'],
      bloodType: studentData['blood_type'],
      isActive: studentData['is_active'] ?? true,
      createdAt: DateTime.parse(studentData['created_at']),
      updatedAt: DateTime.parse(studentData['updated_at']),
    );
  }


// ✅ MÉTODO PARA INSERTAR (sin id y created_at)
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'dni': dni,
      'plan_id': planId,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'blood_type': bloodType,
      'is_active': true, 
    };
  }
  // ✅ MÉTODO PARA INSERTAR (sin id y created_at)
  Map<String, dynamic> toupdateMap() {
    return {
      'name': name,
      'dni': dni,
      'plan_id': planId,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'blood_type': bloodType,
      'is_active': isActive, 
    };
  }

  Student copyWith({
    String? name,
    String? dni,
    int? planId,
    String? lastName,
    String? email,
    String? phone,
    String? emergencyContact,
    DateTime? dateOfBirth,
    String? medicalConditions,
    String? bloodType,
  }) 
  {
    return Student(
      id: id,
      name: name ?? this.name,
      dni: dni ?? this.dni,
      planId: planId ?? this.planId,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      bloodType: bloodType ?? this.bloodType,
      createdAt: createdAt,
      isActive: isActive,
      updatedAt: updatedAt,
    );
  }

  // ------ Metodos de conveniencia -----------

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
}