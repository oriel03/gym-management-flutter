class Plan {
  final String id;
  final String name;
  final int daysPerWeek;
  final double monthlyPrice;
  final DateTime createdAt;

  Plan({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    required this.monthlyPrice,
    required this.createdAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      name: json['name'],
      daysPerWeek: json['days_per_week'],
      monthlyPrice: double.parse(json['monthly_price'].toString()),

      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convertir a JSON (para enviar a Supabase)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days_per_week': daysPerWeek,
      'monthly_price': monthlyPrice,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
