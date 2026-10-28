import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'transaction_details_sheet.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kIncomeColor = Color(0xFF059669);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

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
  State<CategoryDetailsScreen> createState() =>
      _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  int selectedMonthIndex = -1;

  final List<Color> categoryColors = [
    const Color(0xFF0F766E),
    const Color(0xFF14B8A6),
    const Color(0xFF0EA5E9),
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
  ];

  String get category => widget.category;

  int get month => widget.month;

  List<Expense> get expenses => widget.expenses;

  bool get isIncome => widget.isIncome;

  Color get accent => isIncome ? kIncomeColor : kExpenseColor;

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

  double get averageTransaction {
    if (monthExpenses.isEmpty) return 0;

    return categoryTotal / monthExpenses.length;
  }

  Expense? get biggestTransaction {
    if (monthExpenses.isEmpty) return null;

    Expense? biggest;

    for (final expense in monthExpenses) {
      if (biggest == null || expense.amount > biggest.amount) {
        biggest = expense;
      }
    }

    return biggest;
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
    final expectedType = isIncome ? 'INCOME' : 'EXPENSE';

    for (var month = 1; month <= 12; month++) {
      data[month] = 0;
    }

    for (final expense in expenses) {
      final date = DateTime.tryParse(expense.date);

      if (date == null) continue;
      if (date.year != year) continue;

      final expenseCategory = expense.category ?? 'Other';

      if (expense.type.toUpperCase() != expectedType) continue;
      if (expenseCategory != category) continue;

      data[date.month] = data[date.month]! + expense.amount;
    }

    return data;
  }

  String money(double value) {
    if (value.abs() >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }

    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    }

    return '₹${value.toStringAsFixed(0)}';
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
        selectedMonthIndex >= 0 &&
        selectedMonthIndex < visibleMonths.length;

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

        if (dateA == null || dateB == null) return 0;

        return dateB.compareTo(dateA);
      });

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          category,
          style: const TextStyle(
            color: kInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _CategoryHero(
            category: category,
            monthName: monthName,
            total: categoryTotal,
            transactionCount: monthExpenses.length,
            average: averageTransaction,
            biggest: biggestTransaction,
            isIncome: isIncome,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Transactions',
                  value: monthExpenses.length.toString(),
                  icon: Icons.receipt_long_rounded,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Average',
                  value: money(averageTransaction),
                  icon: Icons.calculate_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _SectionHeader(
            title: 'Transactions',
            subtitle:
                '${monthExpenses.length} ${isIncome ? 'income' : 'expense'} entries in $monthName',
          ),

          const SizedBox(height: 14),

          if (sortedExpenses.isEmpty)
            _EmptyCard(
              icon: isIncome
                  ? Icons.savings_rounded
                  : Icons.receipt_long_rounded,
              message:
                  'No $category transactions in $monthName',
            )
          else
            ...sortedExpenses.map(
              (expense) => _TransactionTile(
                expense: expense,
                isIncome: isIncome,
                accent: accent,
                onTap: () {
                  showTransactionDetailsSheet(
                    context: context,
                    expense: expense,
                    onChanged: () {
                      if (mounted) setState(() {});
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 28),

          _Panel(
            title: 'Yearly pattern',
            subtitle:
                'Tap a month to see its share of your yearly $category',
            child: _YearlyCategoryPie(
              data: monthlyData,
              visibleMonths: visibleMonths,
              yearlyTotal: yearlyTotal,
              selectedIndex: selectedMonthIndex,
              selectedMonth: selectedMonth,
              selectedAmount: selectedAmount,
              selectedPercentage: selectedPercentage,
              hasSelection: hasSelection,
              category: category,
              colors: categoryColors,
              onSelected: (index) {
                setState(() {
                  selectedMonthIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHero extends StatelessWidget {
  final String category;
  final String monthName;
  final double total;
  final int transactionCount;
  final double average;
  final Expense? biggest;
  final bool isIncome;

  const _CategoryHero({
    required this.category,
    required this.monthName,
    required this.total,
    required this.transactionCount,
    required this.average,
    required this.biggest,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isIncome
              ? const [Color(0xFF065F46), Color(0xFF059669), Color(0xFF34D399)]
              : const [Color(0xFF0B5D57), Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: isIncome
                ? kIncomeColor.withValues(alpha: 0.28)
                : kPrimary.withValues(alpha: 0.30),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome
                          ? Icons.savings_rounded
                          : Icons.category_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monthName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$transactionCount entries',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            isIncome
                ? category.toUpperCase()
                : '${category.toUpperCase()} SPENDING',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Average',
                  value: average,
                  icon: Icons.calculate_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Highest',
                  value: biggest?.amount ?? 0,
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: kMuted,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Expense expense;
  final bool isIncome;
  final Color accent;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.expense,
    required this.isIncome,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(expense.date);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isIncome
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: accent,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? expense.date
                        : DateFormat('d MMM yyyy').format(date),
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: kMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _YearlyCategoryPie extends StatelessWidget {
  final Map<int, double> data;
  final List<MapEntry<int, double>> visibleMonths;
  final double yearlyTotal;
  final int selectedIndex;
  final int? selectedMonth;
  final double selectedAmount;
  final double selectedPercentage;
  final bool hasSelection;
  final String category;
  final List<Color> colors;
  final ValueChanged<int> onSelected;

  const _YearlyCategoryPie({
    required this.data,
    required this.visibleMonths,
    required this.yearlyTotal,
    required this.selectedIndex,
    required this.selectedMonth,
    required this.selectedAmount,
    required this.selectedPercentage,
    required this.hasSelection,
    required this.category,
    required this.colors,
    required this.onSelected,
  });

  String shortMonth(int month) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: visibleMonths.isEmpty
              ? Center(
                  child: Text(
                    'No yearly data for $category',
                    style: const TextStyle(
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 72,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions) return;

                            if (response == null ||
                                response.touchedSection == null) {
                              onSelected(-1);
                              return;
                            }

                            onSelected(
                              response
                                  .touchedSection!.touchedSectionIndex,
                            );
                          },
                        ),
                        sections:
                            visibleMonths.asMap().entries.map((entry) {
                          final index = entry.key;
                          final amount = entry.value.value;
                          final isSelected = selectedIndex == index;
                          final color = colors[index % colors.length];

                          return PieChartSectionData(
                            value: amount,
                            color: color,
                            radius: isSelected ? 82 : 64,
                            cornerRadius: 14,
                            title:
                                '${(amount / yearlyTotal * 100).toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                                : shortMonth(selectedMonth!),
                            style: const TextStyle(
                              color: kMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                              color: kInk,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasSelection
                              ? '${selectedPercentage.toStringAsFixed(1)}% of yearly total'
                              : 'Tap a slice',
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleMonths.asMap().entries.map((entry) {
            final index = entry.key;
            final month = entry.value.key;
            final amount = entry.value.value;
            final isSelected = selectedIndex == index;
            final color = colors[index % colors.length];

            return GestureDetector(
              onTap: () {
                onSelected(isSelected ? -1 : index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : kBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      shortMonth(month),
                      style: const TextStyle(
                        color: kInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}