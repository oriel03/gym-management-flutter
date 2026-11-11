enum PlanType { libre, semiPersonalizado, personalizado }

extension PlanTypeExtension on PlanType{
  String get value{
    switch (this){
      case PlanType.libre:
      return 'libre';
      case PlanType.semiPersonalizado:
      return 'semiPersonalizado';
      case PlanType.personalizado:
      return 'personalizado';
    }
  }

  static PlanType fromString(String value){
    switch (value){
      case 'Libre':
        return PlanType.libre;
      case 'semiPersonalizado':
        return PlanType.semiPersonalizado;
      case 'personalizado':
        return PlanType.personalizado;
      default:
       throw Exception('unknown plan: $value');
    }
  }
}

class Plan {
  final int id;
  final String name;
  final int daysPerWeek;
  final PlanType? planType;
  final double monthlyPrice;
  final bool isPersonalized;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.name,
    required this.daysPerWeek,
    this.planType,
    required this.monthlyPrice,
    required this.isPersonalized,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  
  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'],
      name: map['name'],
      daysPerWeek: map['days_per_week'],
      planType: map['plan_type'] != null
      ? PlanTypeExtension.fromString(map['plan_type'])
      : null,
      monthlyPrice: (map['monthly_price'] as num).toDouble(),
      isPersonalized: map['is_personalized'] ?? false,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'days_per_week': daysPerWeek,
      'plan_type': planType?.value,
      'monthly_price': monthlyPrice,
      'is_personalized': isPersonalized,
      'description': description,
    };
  }
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'days_per_week': daysPerWeek,
      'plan_type': planType?.value,
      'monthly_price': monthlyPrice,
      'is_personalized': isPersonalized,
      'description': description,
    };
  }
}
