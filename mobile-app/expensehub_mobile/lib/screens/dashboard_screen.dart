import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'reports_screen.dart';
import 'category_details_screen.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final expenseService = ExpenseService();
  final authService = AuthService();
  final budgetController = TextEditingController();
  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  double monthlyBudget = 20000;

  int selectedYearExpenseIndex = -1;
  int selectedIncomeIndex = -1;
  int selectedSavingsIndex = -1;

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

  @override
  void initState() {
    super.initState();
    loadBudget();
    loadExpenses();
  }

  Future<void> openBudgetSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set monthly budget',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This budget will be used for your monthly expense progress.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter budget',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final value = double.tryParse(budgetController.text.trim());

                    if (value == null || value <= 0) {
                      Navigator.pop(context);
                      return;
                    }

                    await authService.setMonthlyBudget(value);

                    if (!mounted) return;

                    setState(() {
                      monthlyBudget = value;
                    });

                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Budget',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> loadBudget() async {
    final budget = await authService.getMonthlyBudget();

    if (!mounted) return;

    setState(() {
      monthlyBudget = budget;
      budgetController.text = budget.toStringAsFixed(0);
    });
  }

  Future<void> loadExpenses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await expenseService.getExpenses();

      if (!mounted) return;

      setState(() {
        expenses = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  List<Expense> getMonthExpenses(int month) {
    final year = selectedYear;

    return expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);

      return date?.year == year && date?.month == month;
    }).toList();
  }

  double getTotalForMonth(int month, String type) {
    double total = 0;

    for (final expense in getMonthExpenses(month)) {
      if (expense.type.toUpperCase() == type) {
        total += expense.amount;
      }
    }

    return total;
  }

  Map<String, double> getCategoryTotals(int month, String type) {
    final totals = <String, double>{};

    for (final expense in getMonthExpenses(month)) {
      if (expense.type.toUpperCase() != type) {
        continue;
      }

      final category = expense.category ?? 'Other';

      totals[category] = (totals[category] ?? 0) + expense.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }

  Map<int, double> getYearlyTotals(String type) {
    final year = selectedYear;
    final data = <int, double>{};

    for (var month = 1; month <= 12; month++) {
      data[month] = 0;
    }

    for (final expense in expenses) {
      final date = DateTime.tryParse(expense.date);

      if (date == null) continue;
      if (date.year != year) continue;

      if (expense.type.toUpperCase() != type) {
        continue;
      }

      data[date.month] = data[date.month]! + expense.amount;
    }

    return data;
  }

  void changeMonth(int change) {
    final now = DateTime.now();

    var newMonth = selectedMonth + change;
    var newYear = selectedYear;

    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    // Block future months
    final isNewMonthInFuture =
        newYear > now.year || (newYear == now.year && newMonth > now.month);

    if (isNewMonthInFuture) return;

    final yearlyExpenses = getYearlyTotals('EXPENSE');
    final yearlyIncome = getYearlyTotals('INCOME');

    final yearlySavings = yearlyIncome.map(
      (month, income) => MapEntry(month, income - yearlyExpenses[month]!),
    );

    final expenseEntries = yearlyExpenses.entries
        .where((entry) => entry.value > 0)
        .toList();

    final incomeEntries = yearlyIncome.entries
        .where((entry) => entry.value > 0)
        .toList();

    final savingsEntries = yearlySavings.entries
        .where((entry) => entry.value > 0)
        .toList();

    final expenseIndex = expenseEntries.indexWhere(
      (entry) => entry.key == newMonth,
    );

    final incomeIndex = incomeEntries.indexWhere(
      (entry) => entry.key == newMonth,
    );

    final savingsIndex = savingsEntries.indexWhere(
      (entry) => entry.key == newMonth,
    );

    setState(() {
      selectedMonth = newMonth;
      selectedYear = newYear;

      selectedYearExpenseIndex = expenseIndex;
      selectedIncomeIndex = incomeIndex;
      selectedSavingsIndex = savingsIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthExpense = getTotalForMonth(selectedMonth, 'EXPENSE');

    final monthIncome = getTotalForMonth(selectedMonth, 'INCOME');

    final budgetUsed = monthlyBudget == 0
        ? 0.0
        : (monthExpense / monthlyBudget).clamp(0.0, 1.0);

    final budgetLeft = monthlyBudget - monthExpense;

    final now = DateTime.now();

    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    final daysLeft = selectedYear == now.year && selectedMonth == now.month
        ? daysInMonth - now.day
        : daysInMonth;

    final dailySafeSpend = daysLeft <= 0 ? 0.0 : budgetLeft / daysLeft;
    final expenseCategories = getCategoryTotals(selectedMonth, 'EXPENSE');

    final incomeCategories = getCategoryTotals(selectedMonth, 'INCOME');

    final yearlyExpenses = getYearlyTotals('EXPENSE');

    final yearlyIncome = getYearlyTotals('INCOME');

    final yearlySavings = yearlyIncome.map(
      (month, income) => MapEntry(month, income - yearlyExpenses[month]!),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          MonthArrows(
            month: selectedMonth,
            year: selectedYear,
            onChanged: changeMonth,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Monthly report',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : RefreshIndicator(
              onRefresh: loadExpenses,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Budget card
                  _BudgetCard(
                    spent: monthExpense,
                    budget: monthlyBudget,
                    percentage: budgetUsed,
                    onEdit: openBudgetSheet,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          title: 'Budget left',
                          value: '₹${budgetLeft.toStringAsFixed(0)}',
                          color: budgetLeft >= 0 ? Colors.green : Colors.red,
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryBox(
                          title: 'Daily safe spend',
                          value: '₹${dailySafeSpend.toStringAsFixed(0)}',
                          color: Colors.blue,
                          icon: Icons.today,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Expense categories
                  _SectionTitle(
                    title: 'Expense categories',
                    subtitle: 'How your money was spent',
                  ),
                  const SizedBox(height: 14),

                  if (expenseCategories.isEmpty)
                    _EmptyCard(message: 'No expenses this month')
                  else
                    _CategoryScrollCard(
                      categories: expenseCategories,
                      total: monthExpense,
                      colors: colors,
                      isIncome: false,
                      selectedMonth: selectedMonth,
                      monthExpenses: getMonthExpenses(selectedMonth),
                    ),
                  const SizedBox(height: 28),

                  // Income categories
                  _SectionTitle(
                    title: 'Income categories',
                    subtitle: 'Where income came from',
                  ),
                  const SizedBox(height: 14),

                  if (incomeCategories.isEmpty)
                    _EmptyCard(message: 'No income this month')
                  else
                    _CategoryScrollCard(
                      categories: incomeCategories,
                      total: monthIncome,
                      colors: colors,
                      isIncome: true,
                      selectedMonth: selectedMonth,
                      monthExpenses: getMonthExpenses(selectedMonth),
                    ),
                  const SizedBox(height: 14),

                  // Yearly expense pie

                  // Yearly expense pie
                  _ChartCard(
                    title: 'Yearly expenses',
                    subtitle: 'Tap a month slice',
                    child: _InteractivePie(
                      data: yearlyExpenses,
                      colors: colors,
                      selectedIndex: selectedYearExpenseIndex,
                      centerTitle: 'Yearly expense',
                      centerAmount: yearlyExpenses.values.fold<double>(
                        0,
                        (total, value) => total + value,
                      ),
                      onTouch: (index) {
                        setState(() {
                          selectedYearExpenseIndex = index;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Income pie
                  _ChartCard(
                    title: 'Yearly income',
                    subtitle: 'Tap a month slice',
                    child: _InteractivePie(
                      data: yearlyIncome,
                      colors: colors,
                      selectedIndex: selectedIncomeIndex,
                      centerTitle: 'Yearly income',
                      centerAmount: yearlyIncome.values.fold<double>(
                        0,
                        (total, value) => total + value,
                      ),
                      onTouch: (index) {
                        setState(() {
                          selectedIncomeIndex = index;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Savings pie
                  _ChartCard(
                    title: 'Yearly savings',
                    subtitle: 'Income minus expense',
                    child: _InteractivePie(
                      data: yearlySavings,
                      colors: colors,
                      selectedIndex: selectedSavingsIndex,
                      centerTitle: 'Yearly savings',
                      centerAmount: yearlySavings.values.fold<double>(
                        0,
                        (total, value) => total + value,
                      ),
                      onTouch: (index) {
                        setState(() {
                          selectedSavingsIndex = index;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _monthName(int month) {
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryProgressCard extends StatelessWidget {
  final String title;
  final double amount;
  final double percentage;
  final Color color;
  final Widget? trailing;

  const _CategoryProgressCard({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  title.characters.first.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% of total',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthArrows extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<int> onChanged;

  const MonthArrows({
    super.key,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  bool get isCurrentMonth {
    final now = DateTime.now();

    return year == now.year && month == now.month;
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArrowButton(icon: Icons.chevron_left, onTap: () => onChanged(-1)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              key: ValueKey('$month-$year'),
              '${months[month - 1]} $year',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ArrowButton(
            icon: Icons.chevron_right,
            onTap: isCurrentMonth ? null : () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ArrowButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _InteractivePie extends StatelessWidget {
  final Map<int, double> data;
  final List<Color> colors;
  final int selectedIndex;
  final String centerTitle;
  final double centerAmount;
  final ValueChanged<int> onTouch;

  const _InteractivePie({
    required this.data,
    required this.colors,
    required this.selectedIndex,
    required this.centerTitle,
    required this.centerAmount,
    required this.onTouch,
  });

  List<Color> getGradientColors(Color baseColor) {
    return [baseColor, baseColor.withValues(alpha: 0.55)];
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((entry) => entry.value > 0).toList();

    final hasSelection = selectedIndex >= 0 && selectedIndex < entries.length;

    final selectedMonth = hasSelection ? entries[selectedIndex].key : null;

    final selectedAmount = hasSelection
        ? entries[selectedIndex].value
        : centerAmount;

    final selectedPercentage = centerAmount == 0
        ? 0.0
        : selectedAmount / centerAmount * 100;

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

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 72,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) {
                        return;
                      }

                      if (response == null || response.touchedSection == null) {
                        onTouch(-1);
                        return;
                      }

                      onTouch(response.touchedSection!.touchedSectionIndex);
                    },
                  ),
                  sections: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final month = entry.value.key;
                    final amount = entry.value.value;

                    final isSelected = selectedIndex == index;

                    final baseColor = colors[index % colors.length];

                    final percentage = centerAmount == 0
                        ? 0.0
                        : amount / centerAmount * 100;

                    return PieChartSectionData(
                      value: amount,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: getGradientColors(baseColor),
                      ),
                      radius: isSelected ? 84 : 62,
                      cornerRadius: 12,
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
                          ? centerTitle
                          : months[selectedMonth! - 1],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasSelection
                        ? '${selectedPercentage.toStringAsFixed(1)}% of total'
                        : 'Tap a slice',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final month = entry.value.key;
            final amount = entry.value.value;

            final isSelected = selectedIndex == index;

            final baseColor = colors[index % colors.length];

            return GestureDetector(
              onTap: () => onTouch(isSelected ? -1 : index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            baseColor,
                            baseColor.withValues(alpha: 0.65),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: baseColor.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      months[month - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
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
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _CategoryScrollCard extends StatelessWidget {
  final Map<String, double> categories;
  final double total;
  final List<Color> colors;
  final bool isIncome;
  final int selectedMonth;
  final List<Expense> monthExpenses;

  const _CategoryScrollCard({
    required this.categories,
    required this.total,
    required this.colors,
    required this.isIncome,
    required this.selectedMonth,
    required this.monthExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList();

    return Container(
      height: 360,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isIncome ? Colors.green.shade100 : Colors.red.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isIncome ? 'Income categories' : 'Expense categories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                'Scroll for more',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];

                final percentage = total == 0 ? 0.0 : entry.value / total;

                final color = colors[index % colors.length];

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailsScreen(
                          category: entry.key,
                          month: selectedMonth,
                          expenses: monthExpenses,
                          isIncome: isIncome,
                        ),
                      ),
                    );
                  },
                  child: _CategoryProgressCard(
                    title: entry.key,
                    amount: entry.value,
                    percentage: percentage,
                    color: color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double percentage;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.spent,
    required this.budget,
    required this.percentage,
    required this.onEdit,
  });

  Color get progressColor {
    if (percentage >= 1) {
      return Colors.red.shade400;
    }

    if (percentage >= 0.8) {
      return Colors.orange.shade600;
    }

    return Colors.teal.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 15,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                iconSize: 17,
                color: Colors.teal.shade600,
                tooltip: 'Edit budget',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${spent.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF134E4A),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'of ₹${budget.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal.shade700.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.teal.shade50,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
