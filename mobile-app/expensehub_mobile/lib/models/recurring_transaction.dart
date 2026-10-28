import '../utils/json_utils.dart';

class RecurringTransaction {
  final String? id;
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
    Map<String, dynamic> json,
  ) {
    return RecurringTransaction(
      id: JsonUtils.parseOptionalId(json['id']),
      title: JsonUtils.parseString(json['title']),
      amount: JsonUtils.parseDouble(json['amount']),
      type: JsonUtils.parseString(
        json['type'],
        fallback: 'EXPENSE',
      ),
      category: JsonUtils.parseString(
        json['category'],
        fallback: 'Other',
      ),
      description: JsonUtils.parseOptionalString(json['description']),
      frequency: JsonUtils.parseString(
        json['frequency'],
        fallback: 'MONTHLY',
      ),
      startDate: DateTime.tryParse(
            JsonUtils.parseString(json['startDate']),
          ) ??
          DateTime.now(),
      nextDueDate: DateTime.tryParse(
            JsonUtils.parseString(json['nextDueDate']),
          ) ??
          DateTime.now(),
      active: JsonUtils.parseBool(
        json['active'],
        fallback: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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