import '../utils/json_utils.dart';

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
      categoryName: JsonUtils.parseOptionalString(
        json['categoryName'],
      ),
      totalAmount: JsonUtils.parseDouble(json['totalAmount']),
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
      year: int.tryParse(
            JsonUtils.parseString(json['year']),
          ) ??
          0,
      month: int.tryParse(
            JsonUtils.parseString(json['month']),
          ) ??
          0,
      totalIncome: JsonUtils.parseDouble(json['totalIncome']),
      totalExpense: JsonUtils.parseDouble(json['totalExpense']),
      savings: JsonUtils.parseDouble(json['savings']),
      categorySummary: (json['categorySummary'] as List? ?? [])
          .map(
            (item) => CategorySummary.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}