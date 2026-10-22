class CategorySummary {
  final String? categoryName;
  final double totalAmount;


  CategorySummary({
    required this.totalAmount,
    this.categoryName,
  });


  factory CategorySummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return CategorySummary(
      categoryName: json['categoryName'] as String?,
      totalAmount:
          (json['totalAmount'] as num).toDouble(),
    );
  }
}


class MonthlyReport {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double savings;
  final List<CategorySummary> categorySummary;


  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.savings,
    required this.categorySummary,
  });


  factory MonthlyReport.fromJson(
    Map<String, dynamic> json,
  ) {
    return MonthlyReport(
      year: json['year'] as int,
      month: json['month'] as int,
      totalIncome:
          (json['totalIncome'] as num).toDouble(),
      totalExpense:
          (json['totalExpense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      categorySummary:
          (json['categorySummary'] as List? ?? [])
              .map(
                (item) => CategorySummary.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}