import '../utils/json_utils.dart';

class Expense {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final String? categoryId;
  final String? category;
  final String? createdAt;

  final bool isRecurring;
  final String? recurringFrequency;
  final String? recurringStartDate;
  final String? nextDueDate;

  Expense({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryId,
    this.category,
    this.createdAt,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringStartDate,
    this.nextDueDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'];

    String? categoryName;
    String? categoryId;

    if (categoryValue is String) {
      categoryName = categoryValue;
    } else if (categoryValue is Map<String, dynamic>) {
      categoryName = JsonUtils.parseOptionalString(categoryValue['name']);
      categoryId = JsonUtils.parseOptionalId(categoryValue['id']);
    }

    return Expense(
      id: JsonUtils.parseId(json['id']),
      type: JsonUtils.parseString(json['type'], fallback: 'EXPENSE'),
      amount: JsonUtils.parseDouble(json['amount']),
      description: JsonUtils.parseString(json['description']),
      date: JsonUtils.parseString(json['date']),
      categoryId:
          categoryId ??
          JsonUtils.parseOptionalId(json['categoryId']) ??
          JsonUtils.parseOptionalId(json['category_id']),
      category: categoryName,
      createdAt: JsonUtils.parseOptionalString(json['createdAt']),
      isRecurring: JsonUtils.parseBool(json['isRecurring']),
      recurringFrequency: JsonUtils.parseOptionalString(
        json['recurringFrequency'],
      ),
      recurringStartDate: JsonUtils.parseOptionalString(
        json['recurringStartDate'],
      ),
      nextDueDate: JsonUtils.parseOptionalString(json['nextDueDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
      'categoryId': categoryId,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'recurringStartDate': recurringStartDate,
      'nextDueDate': nextDueDate,
    };
  }
}
