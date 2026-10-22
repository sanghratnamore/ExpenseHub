class RecurringTransaction {
  final int? id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String? description;
  final String frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool active;


  RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.active = true,
  });


  factory RecurringTransaction.fromJson(
      Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as int?,
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] ?? 'EXPENSE',
      category: json['category'] ?? 'Other',
      description: json['description'],
      frequency: json['frequency'] ?? 'MONTHLY',
      startDate: DateTime.parse(
        json['startDate'] ??
            DateTime.now().toIso8601String(),
      ),
      nextDueDate: DateTime.parse(
        json['nextDueDate'] ??
            DateTime.now().toIso8601String(),
      ),
      active: json['active'] ?? true,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'frequency': frequency,
      'startDate': startDate
          .toIso8601String()
          .substring(0, 10),
    };
  }
}