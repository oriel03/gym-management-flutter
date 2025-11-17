class Plan {
  final String id;
  final String name;
  final int daysPerWeek; // ⚠️ CORREGIDO: Cambiar de dayPerWeek a daysPerWeek
  final double monthlyPrice;
  final bool isPersonalized;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    required this.monthlyPrice,
    required this.isPersonalized,
    required this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'],
      daysPerWeek:
          json['days_per_week'], // ⚠️ CORREGIDO: Ahora coincide con el nombre de variable
      monthlyPrice: double.parse(json['monthly_price'].toString()),
      isPersonalized: json['is_personalized'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'],
      ), // ⚠️ CORREGIDO: Cambiar de 'create_At' a 'created_at'
    );
  }

  // Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days_per_week': daysPerWeek, // ⚠️ CORREGIDO: Usar el nombre correcto
      'monthly_price': monthlyPrice,
      'is_personalized': isPersonalized,
    };
  }

  // ✅ AGREGAR: Método copyWith para facilitar actualizaciones
  Plan copyWith({
    String? id,
    String? name,
    int? daysPerWeek,
    double? monthlyPrice,
    bool? isPersonalized,
    DateTime? createdAt,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      isPersonalized: isPersonalized ?? this.isPersonalized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
