class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? workArea;
  final String? username;
  final String? pin;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.workArea,
    this.username,
    this.pin,
    this.isActive =
        true, // ⚠️ CORREGIDO: Cambiar de false a true (debe coincidir con SQL DEFAULT true)
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      workArea: json['work_area'],
      username: json['username'],
      pin: json['pin'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'work_area': workArea,
      'username': username,
      'pin': pin,
      'is_active': isActive,
    };
  }

  // ✅ MÉTODO PARA INSERTAR (sin id y created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'email': email,
      'work_area': workArea,
      'username': username,
      'pin': pin,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? workArea,
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
    );
  }
}
