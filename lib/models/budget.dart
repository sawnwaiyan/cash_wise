class Budget {
  final int? id;
  final int categoryId;
  final String monthLabel;
  final int amount;

  const Budget({
    this.id,
    required this.categoryId,
    required this.monthLabel,
    required this.amount,
  });

  Budget copyWith({int? id, int? categoryId, String? monthLabel, int? amount}) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthLabel: monthLabel ?? this.monthLabel,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'month_label': monthLabel,
      'amount': amount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      monthLabel: map['month_label'] as String,
      amount: map['amount'] as int,
    );
  }
}