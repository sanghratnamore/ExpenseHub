import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
    final year = DateTime.now().year;

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
    final year = DateTime.now().year;

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
    var newMonth = selectedMonth + change;

    if (newMonth < 1) newMonth = 12;
    if (newMonth > 12) newMonth = 1;

    setState(() {
      selectedMonth = newMonth;
      selectedYearExpenseIndex = -1;
      selectedIncomeIndex = -1;
      selectedSavingsIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthExpense = getTotalForMonth(selectedMonth, 'EXPENSE');

    final monthIncome = getTotalForMonth(selectedMonth, 'INCOME');

    final monthSavings = monthIncome - monthExpense;

    final budgetUsed = monthlyBudget == 0
        ? 0.0
        : (monthExpense / monthlyBudget).clamp(0.0, 1.0);

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
          IconButton(onPressed: loadExpenses, icon: const Icon(Icons.refresh)),
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
                  _CategoryProgressCard(
                    title: 'Monthly budget',
                    amount: monthExpense,
                    percentage: budgetUsed,
                    color: colors.first,
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
                    ...expenseCategories.entries.map((entry) {
                      final percentage = monthExpense == 0
                          ? 0.0
                          : entry.value / monthExpense;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailsScreen(
                                category: entry.key,
                                month: selectedMonth,
                                expenses: getMonthExpenses(selectedMonth),
                              ),
                            ),
                          );
                        },
                        child: _CategoryProgressCard(
                          title: entry.key,
                          amount: entry.value,
                          percentage: percentage,
                          color:
                              colors[expenseCategories.keys.toList().indexOf(
                                    entry.key,
                                  ) %
                                  colors.length],
                        ),
                      );
                    }),

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
                    ...incomeCategories.entries.map((entry) {
                      final percentage = monthIncome == 0
                          ? 0.0
                          : entry.value / monthIncome;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailsScreen(
                                category: entry.key,
                                month: selectedMonth,
                                expenses: getMonthExpenses(selectedMonth),
                                isIncome: true,
                              ),
                            ),
                          );
                        },
                        child: _CategoryProgressCard(
                          title: entry.key,
                          amount: entry.value,
                          percentage: percentage,
                          color:
                              colors[incomeCategories.keys.toList().indexOf(
                                    entry.key,
                                  ) %
                                  colors.length],
                        ),
                      );
                    }),
                  const SizedBox(height: 14),

                  // Yearly expense pie
                  _ChartCard(
                    title: 'Yearly expenses',
                    subtitle: 'Tap a month slice',
                    trailing: _MonthArrows(
                      month: selectedMonth,
                      onChanged: changeMonth,
                    ),
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

  const _CategoryProgressCard({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
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

class _MonthArrows extends StatelessWidget {
  final int month;
  final ValueChanged<int> onChanged;

  const _MonthArrows({required this.month, required this.onChanged});

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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(-1),
            icon: const Icon(Icons.chevron_left, size: 20),
          ),
          Text(
            months[month - 1],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(1),
            icon: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
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
        borderRadius: BorderRadius.circular(26),
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
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 68,
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

                    final percentage = centerAmount == 0
                        ? 0.0
                        : amount / centerAmount * 100;

                    return PieChartSectionData(
                      value: amount,
                      color: colors[index % colors.length],
                      radius: isSelected ? 82 : 60,
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
          spacing: 14,
          runSpacing: 10,
          children: entries.asMap().entries.map((entry) {
            final index = entry.key;

            final month = entry.value.key;

            final amount = entry.value.value;

            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () => onTouch(isSelected ? -1 : index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors[index % colors.length].withValues(alpha: 0.15)
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
                      months[month - 1],
                      style: TextStyle(
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
