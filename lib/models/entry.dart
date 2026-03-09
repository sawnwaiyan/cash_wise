class Entry {
  final int? id;
  final DateTime date;
  final int categoryId;
  final int amount;
  final String? note;
  final DateTime createdAt;

  const Entry({
    this.id,
    required this.date,
    required this.categoryId,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  Entry copyWith({
    int? id,
    DateTime? date,
    int? categoryId,
    int? amount,
    String? note,
    DateTime? createdAt,
  }) {
    return Entry(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'category_id': categoryId,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      amount: map['amount'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}