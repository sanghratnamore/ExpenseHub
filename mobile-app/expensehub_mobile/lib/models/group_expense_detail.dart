class GroupExpenseSplit {
  final int id;
  final int userId;
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
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      shareAmount:
          (json['shareAmount'] as num).toDouble(),
    );
  }
}


class GroupExpenseDetail {
  final int id;
  final String description;
  final double amount;
  final String expenseDate;
  final int paidById;
  final String paidByName;
  final int? categoryId;
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
      id: json['id'] as int,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: json['expenseDate'] as String,
      paidById: json['paidById'] as int,
      paidByName: json['paidByName'] as String,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
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