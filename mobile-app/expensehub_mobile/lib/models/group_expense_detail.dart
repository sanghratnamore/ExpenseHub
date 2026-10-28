import '../utils/json_utils.dart';

class GroupExpenseSplit {
  final String id;
  final String userId;
  final String? userName;
  final double shareAmount;

  GroupExpenseSplit({
    required this.id,
    required this.userId,
    required this.shareAmount,
    this.userName,
  });

  factory GroupExpenseSplit.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupExpenseSplit(
      id: JsonUtils.parseId(json['id']),
      userId: JsonUtils.parseId(json['userId']),
      userName: JsonUtils.parseOptionalString(json['userName']),
      shareAmount: JsonUtils.parseDouble(json['shareAmount']),
    );
  }
}

class GroupExpenseDetail {
  final String id;
  final String description;
  final double amount;
  final String expenseDate;
  final String paidById;
  final String paidByName;
  final String? categoryId;
  final String? categoryName;
  final List<GroupExpenseSplit> splits;

  GroupExpenseDetail({
    required this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.paidById,
    required this.paidByName,
    required this.splits,
    this.categoryId,
    this.categoryName,
  });

  factory GroupExpenseDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupExpenseDetail(
      id: JsonUtils.parseId(json['id']),
      description: JsonUtils.parseString(json['description']),
      amount: JsonUtils.parseDouble(json['amount']),
      expenseDate: JsonUtils.parseString(json['expenseDate']),
      paidById: JsonUtils.parseId(json['paidById']),
      paidByName: JsonUtils.parseString(json['paidByName']),
      categoryId: JsonUtils.parseOptionalId(json['categoryId']),
      categoryName: JsonUtils.parseOptionalString(json['categoryName']),
      splits: (json['splits'] as List? ?? [])
          .map(
            (item) => GroupExpenseSplit.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}