class Expense {
  final int id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final int? categoryId;
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


  factory Expense.fromJson(
    Map<String, dynamic> json,
  ) {
    final categoryValue = json['category'];


    String? categoryName;


    if (categoryValue is String) {
      categoryName = categoryValue;
    } else if (categoryValue
        is Map<String, dynamic>) {
      categoryName =
          categoryValue['name']?.toString();
    }


    return Expense(
      id: json['id'] is int
          ? json['id']
          : int.parse(
              json['id'].toString(),
            ),
      type: json['type']?.toString() ??
          'EXPENSE',
      amount:
          (json['amount'] as num?)?.toDouble() ??
              0,
      description:
          json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      categoryId: json['categoryId'] is int
          ? json['categoryId']
          : int.tryParse(
              json['categoryId']?.toString() ??
                  '',
            ),
      category: categoryName,
      createdAt:
          json['createdAt']?.toString(),
      isRecurring:
          json['isRecurring'] == true,
      recurringFrequency: json[
              'recurringFrequency']
          ?.toString(),
      recurringStartDate: json[
              'recurringStartDate']
          ?.toString(),
      nextDueDate:
          json['nextDueDate']?.toString(),
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
      'recurringFrequency':
          recurringFrequency,
      'recurringStartDate':
          recurringStartDate,
      'nextDueDate': nextDueDate,
    };
  }
}