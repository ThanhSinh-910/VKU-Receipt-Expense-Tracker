class Expense {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final String? note;
  final String? imagePath;
  final String? rawOcrText;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    this.imagePath,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Không xác định',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      category: map['category'] as String? ?? 'Khác',
      note: map['note'] as String?,
      imagePath: map['imagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Expense copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    String? category,
    String? note,
    String? imagePath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> categories = [
    'Ăn uống',
    'Mua sắm',
    'Di chuyển',
    'Học tập',
    'Hóa đơn',
    'Khác',
  ];
}
