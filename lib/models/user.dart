enum WorkArea { admin, bigClass, smallClass}


extension WorkAreaExtension on WorkArea{
  String get value{
    switch (this){
      case WorkArea.admin:
      return 'admin';
      case WorkArea.bigClass:
      return 'big_class';
      case WorkArea.smallClass:
      return 'small_class';
    }
  }

  static WorkArea fromString(String value){
    switch (value){
      case 'admin':
        return WorkArea.admin;
      case 'big_class':
        return WorkArea.bigClass;
      case 'small_class':
        return WorkArea.smallClass;
      default:
       throw Exception('unknown WorkArea: $value');
    }
  }
}



class UserModel {
  final String id;
  final String? name;
  final String? username;
  final String email;
  final WorkArea? workArea;
  final String? pin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.workArea,
    required this.username,
    this.pin,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      workArea: map['work_area'] != null
      ? WorkAreaExtension.fromString(map['work_area'])
      : null,
      username: map['username'],
      pin: map['pin'],
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // ✅ MÉTODO PARA INSERTAR (sin id y created_at)
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'email': email,
      'work_area': workArea?.value,
      'username': username,
      'pin': pin,
      'is_active': true, 
    };
  }
  // ✅ MÉTODO PARA INSERTAR (sin id y created_at)
  Map<String, dynamic> toupdateMap() {
    return {
      'name': name,
      'email': email,
      'work_area': workArea?.value,
      'username': username,
      'pin': pin,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    WorkArea? workArea,
    String? username,
    String? pin,
    bool? isActive,
    DateTime? createdAt,
    
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      workArea: workArea ?? this.workArea,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt,
    );
  }
}
