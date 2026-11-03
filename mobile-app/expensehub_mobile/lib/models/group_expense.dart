import '../utils/json_utils.dart';

class GroupExpense {
  final String id;
  final String description;
  final double amount;
  final String expenseDate;
  final String paidById;
  final String paidByName;

  final String? createdAt;

  final String? updatedByName;
  final DateTime? updatedAt;
  final int version;

  final bool isDeleted;
  final String? deletedByName;
  final DateTime? deletedAt;

  GroupExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.paidById,
    required this.paidByName,
    this.createdAt,
    this.updatedByName,
    this.updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.deletedByName,
    this.deletedAt,
  });

  factory GroupExpense.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupExpense(
      id: JsonUtils.parseId(json['id']),
      description: JsonUtils.parseString(
        json['description'],
      ),
      amount: JsonUtils.parseDouble(json['amount']),
      expenseDate: JsonUtils.parseString(
        json['expenseDate'],
      ),
      paidById: JsonUtils.parseId(json['paidById']),
      paidByName: JsonUtils.parseString(
        json['paidByName'],
      ),
      createdAt: parseCreatedAtValue(
        json['createdAt'] ?? json['created_at'],
      ),
      updatedByName: JsonUtils.parseOptionalString(
        json['updatedByName'],
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      version: json['version'] ?? 1,
      isDeleted: json['isDeleted'] ?? false,
      deletedByName: JsonUtils.parseOptionalString(
        json['deletedByName'],
      ),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  static String? parseCreatedAtValue(dynamic value) {
    if (value == null) return null;

    if (value is List && value.isNotEmpty) {
      if (value.length >= 3) {
        final year = value[0];
        final month =
            value[1].toString().padLeft(2, '0');
        final day =
            value[2].toString().padLeft(2, '0');

        String hour = '00';
        String minute = '00';
        String second = '00';

        if (value.length >= 6) {
          hour = value[3]
              .toString()
              .padLeft(2, '0');
          minute = value[4]
              .toString()
              .padLeft(2, '0');
          second = value[5]
              .toString()
              .padLeft(2, '0');
        }

        return '$year-$month-$day'
            'T$hour:$minute:$second';
      }

      return value.join('-');
    }

    return value.toString();
  }
}