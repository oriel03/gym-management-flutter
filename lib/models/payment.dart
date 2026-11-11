// Tipos alineados con la tabla `payments` de Supabase:
//   id, student_plan_id, student_id -> integer  => int
//   registered_by                   -> uuid     => String
//   amount                          -> numeric  => double (solo para mostrar;
//                                      el cálculo de dinero va en SQL)

enum PaymentStatus {
  pago('pago'),
  pendiente('pendiente'),
  adeuda('adeuda');

  const PaymentStatus(this.value);
  final String value;

  // Falla con un error claro si llega un valor desconocido, en vez de
  // convertirlo en silencio a "pendiente" (eso mostraría un dato falso).
  static PaymentStatus fromString(String value) => PaymentStatus.values
      .firstWhere((s) => s.value == value,
          orElse: () => throw FormatException('PaymentStatus desconocido: $value'));
}

enum PaymentMethod {
  transferencia('transferencia'),
  efectivo('efectivo'),
  tarjeta('tarjeta');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) => PaymentMethod.values
      .firstWhere((m) => m.value == value,
          orElse: () => throw FormatException('PaymentMethod desconocido: $value'));
}

class Payment {
  final int id;
  final int studentPlanId;
  final int studentId;
  final double amount;
  final DateTime paymentDate;
  final DateTime dueDate;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String? transactionReference;
  final String? notes;
  final int? periodMonth;
  final int? periodYear;
  final String? registeredBy; // uuid del usuario que registró el pago
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.studentPlanId,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.dueDate,
    required this.paymentStatus,
    this.paymentMethod,
    this.transactionReference,
    this.notes,
    this.periodMonth,
    this.periodYear,
    this.registeredBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int,
      studentPlanId: map['student_plan_id'] as int,
      studentId: map['student_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      paymentStatus: PaymentStatus.fromString(map['payment_status'] as String),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.fromString(map['payment_method'] as String)
          : null,
      transactionReference: map['transaction_reference'] as String?,
      notes: map['notes'] as String?,
      periodMonth: map['period_month'] as int?,
      periodYear: map['period_year'] as int?,
      registeredBy: map['registered_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // No se manda `registered_by`: la base lo completa sola con el usuario
  // logueado (default auth.uid()), así nadie puede firmar un pago con
  // el nombre de otro.
  Map<String, dynamic> toInsertMap() {
    return {
      'student_plan_id': studentPlanId,
      'student_id': studentId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      'payment_status': paymentStatus.value,
      'payment_method': paymentMethod?.value,
      'transaction_reference': transactionReference,
      'notes': notes,
      'period_month': periodMonth,
      'period_year': periodYear,
    };
  }
}
