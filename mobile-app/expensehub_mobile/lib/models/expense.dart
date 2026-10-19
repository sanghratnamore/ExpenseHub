class Expense {
  final int id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final String category;
  final int categoryId;
  final String? createdAt;

  Expense({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    required this.categoryId,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    
    int categoryId = 0;
    String categoryName = 'Uncategorized';

    if (categoryJson is Map<String, dynamic>) {
      categoryId = categoryJson['id'] ?? 0;
      categoryName = categoryJson['name'] ?? 'Uncategorized';
    } else if (categoryJson is String) {
      categoryName = categoryJson;
    }

    return Expense(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'EXPENSE',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0,
      description: json['description'] ?? 'No description',
      date: json['date'] ?? '',
      category: categoryName,
      categoryId: categoryId,
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }
}