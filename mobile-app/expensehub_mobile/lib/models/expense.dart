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
  final String? updatedByName;
  final DateTime? updatedAt;
  final int version;
  final bool isDeleted;
  final String? deletedByName;
  final DateTime? deletedAt;

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
    this.updatedByName,
    this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedByName,
    this.deletedAt,
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
      createdAt: parseCreatedAtValue(json['createdAt']),
      isRecurring: JsonUtils.parseBool(json['isRecurring']),
      recurringFrequency: JsonUtils.parseOptionalString(
        json['recurringFrequency'],
      ),
      recurringStartDate: JsonUtils.parseOptionalString(
        json['recurringStartDate'],
      ),
      nextDueDate: JsonUtils.parseOptionalString(json['nextDueDate']),

      updatedByName: json['updatedByName'],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      version: json['version'] ?? 1,
      isDeleted: json['isDeleted'] ?? false,
      deletedByName: json['deletedByName'],
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  static String? parseCreatedAtValue(dynamic value) {
    if (value == null) return null;

    if (value is List && value.isNotEmpty) {
      // Spring Boot can return [year, month, day, hour, minute, second]
      if (value.length >= 3) {
        final year = value[0];
        final month = value[1].toString().padLeft(2, '0');
        final day = value[2].toString().padLeft(2, '0');

        String hour = '00';
        String minute = '00';
        String second = '00';

        if (value.length >= 6) {
          hour = value[3].toString().padLeft(2, '0');
          minute = value[4].toString().padLeft(2, '0');
          second = value[5].toString().padLeft(2, '0');
        }

        return '$year-$month-$day T$hour:$minute:$second'.replaceAll(' T', 'T');
      }

      return value.join('-');
    }

    return value.toString();
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
