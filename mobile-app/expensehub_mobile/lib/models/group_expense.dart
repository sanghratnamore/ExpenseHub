class GroupExpense {
  final int id;
  final String description;
  final double amount;
  final String expenseDate;
  final int paidById;
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? '',
      amount:
          (json['amount'] as num?)?.toDouble() ?? 0,
      expenseDate: json['expenseDate'] ?? '',
      paidById: (json['paidById'] as num?)?.toInt() ?? 0,
      paidByName: json['paidByName'] ?? '',
    );
  }
}