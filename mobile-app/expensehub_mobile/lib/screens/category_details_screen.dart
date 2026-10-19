import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_details_sheet.dart';
import '../models/expense.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String category;
  final int month;
  final List<Expense> expenses;
  final bool isIncome;

  const CategoryDetailsScreen({
    super.key,
    required this.category,
    required this.month,
    required this.expenses,
    this.isIncome = false,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  int selectedMonthIndex = -1;

  final colors = [
    const Color(0xFF0EA5E9),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFF6366F1),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
  ];

  String get category => widget.category;
  int get month => widget.month;
  List<Expense> get expenses => widget.expenses;
  bool get isIncome => widget.isIncome;

  List<Expense> get monthExpenses {
    final expectedType = isIncome ? 'INCOME' : 'EXPENSE';

    return expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);

      final expenseCategory = expense.category ?? 'Other';

      return date?.month == month &&
          expenseCategory == category &&
          expense.type.toUpperCase() == expectedType;
    }).toList();
  }

  double get categoryTotal {
    double total = 0;

    for (final expense in monthExpenses) {
      total += expense.amount;
    }

    return total;
  }

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  Map<int, double> getMonthlyCategoryTotals() {
    final year = DateTime.now().year;

    final data = <int, double>{};

    for (var month = 1; month <= 12; month++) {
      data[month] = 0;
    }

    for (final expense in expenses) {
      final date = DateTime.tryParse(expense.date);

      if (date == null) continue;
      if (date.year != year) continue;

      final expenseCategory = expense.category ?? 'Other';

      final expectedType = isIncome ? 'INCOME' : 'EXPENSE';

      if (expense.type.toUpperCase() != expectedType) {
        continue;
      }

      if (expenseCategory != category) {
        continue;
      }

      data[date.month] = data[date.month]! + expense.amount;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = getMonthlyCategoryTotals();

    final visibleMonths = monthlyData.entries
        .where((entry) => entry.value > 0)
        .toList();

    final yearlyTotal = visibleMonths.fold<double>(
      0,
      (total, entry) => total + entry.value,
    );

    final hasSelection =
        selectedMonthIndex >= 0 && selectedMonthIndex < visibleMonths.length;

    final selectedMonth = hasSelection
        ? visibleMonths[selectedMonthIndex].key
        : null;

    final selectedAmount = hasSelection
        ? visibleMonths[selectedMonthIndex].value
        : categoryTotal;

    final selectedPercentage = yearlyTotal == 0
        ? 0.0
        : selectedAmount / yearlyTotal * 100;

    final sortedExpenses = List<Expense>.from(monthExpenses)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt ?? a.date);

        final dateB = DateTime.tryParse(b.createdAt ?? b.date);

        if (dateA == null || dateB == null) {
          return 0;
        }

        return dateB.compareTo(dateA);
      });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('$category Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // Category total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$category spending',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${categoryTotal.toStringAsFixed(0)} in $monthName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: 1,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.teal.shade700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Transactions
          Text(
            'All $category transactions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 14),

          if (sortedExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'No $category transactions in $monthName',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...sortedExpenses.map((expense) {
              final date = DateTime.tryParse(expense.date);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showTransactionDetailsSheet(
                    context: context,
                    expense: expense,
                    onChanged: () {
                      setState(() {});
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isIncome
                              ? Colors.green.shade50
                              : Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.receipt_long,
                          color: isIncome ? Colors.green : Colors.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date == null
                                  ? expense.date
                                  : DateFormat('d MMM yyyy').format(date),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 28),

          // Yearly category pie chart
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yearly category spending',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a month slice',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 65,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) {
                                return;
                              }

                              if (response == null ||
                                  response.touchedSection == null) {
                                setState(() {
                                  selectedMonthIndex = -1;
                                });
                                return;
                              }

                              setState(() {
                                selectedMonthIndex = response
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                          ),
                          sections: visibleMonths.asMap().entries.map((entry) {
                            final index = entry.key;

                            final monthData = entry.value;

                            final month = monthData.key;

                            final amount = monthData.value;

                            final isSelected = selectedMonthIndex == index;

                            final percentage = yearlyTotal == 0
                                ? 0.0
                                : amount / yearlyTotal * 100;

                            return PieChartSectionData(
                              value: amount,
                              color: colors[index % colors.length],
                              radius: isSelected ? 80 : 60,
                              title: '${percentage.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              showTitle: isSelected,
                            );
                          }).toList(),
                        ),
                      ),
                      Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              key: ValueKey(selectedMonth),
                              selectedMonth == null
                                  ? category
                                  : _shortMonthName(selectedMonth!),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              key: ValueKey(selectedAmount),
                              '₹${selectedAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasSelection
                                ? '${selectedPercentage.toStringAsFixed(1)}% of yearly total'
                                : 'Tap a slice',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: visibleMonths.asMap().entries.map((entry) {
                    final index = entry.key;

                    final monthData = entry.value;

                    final month = monthData.key;

                    final amount = monthData.value;

                    final isSelected = selectedMonthIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMonthIndex = isSelected ? -1 : index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors[index % colors.length].withValues(
                                  alpha: 0.15,
                                )
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _shortMonthName(month),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}
