import '../utils/json_utils.dart';

class GroupExpense {
  final String id;
  final String description;
  final double amount;
  final String expenseDate;
  final String paidById;
  final String paidByName;

  GroupExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.paidById,
    required this.paidByName,
  });

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    return GroupExpense(
      id: JsonUtils.parseId(json['id']),
      description: JsonUtils.parseString(json['description']),
      amount: JsonUtils.parseDouble(json['amount']),
      expenseDate: JsonUtils.parseString(json['expenseDate']),
      paidById: JsonUtils.parseId(json['paidById']),
      paidByName: JsonUtils.parseString(json['paidByName']),
    );
  }
}