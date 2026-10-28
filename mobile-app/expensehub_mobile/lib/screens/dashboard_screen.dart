import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import 'category_details_screen.dart';
import 'reports_screen.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kIncomeColor = Color(0xFF059669);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final expenseService = ExpenseService();
  final authService = AuthService();
  final budgetController = TextEditingController();

  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  double monthlyBudget = 20000;
  String selectedMetric = 'Expenses';

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

  @override
  void initState() {
    super.initState();
    loadBudget();
    loadExpenses();
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadBudget(), loadExpenses()]);
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

  Future<void> openBudgetSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly budget',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set a monthly limit to track your spending progress.',
                style: TextStyle(color: kMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: kSurface,
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
                      Navigator.pop(sheetContext);
                      return;
                    }

                    await authService.setMonthlyBudget(value);

                    if (!mounted) return;

                    setState(() {
                      monthlyBudget = value;
                    });

                    Navigator.pop(sheetContext);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save budget',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Expense> getMonthExpenses(int month) {
    return expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);

      return date?.year == selectedYear && date?.month == month;
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
      if (expense.type.toUpperCase() != type) continue;

      final category = expense.category ?? 'Other';

      totals[category] = (totals[category] ?? 0) + expense.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }

  Map<int, double> getYearlyTotals(String type) {
    final data = <int, double>{};

    for (var month = 1; month <= 12; month++) {
      data[month] = 0;
    }

    for (final expense in expenses) {
      final date = DateTime.tryParse(expense.date);

      if (date == null) continue;
      if (date.year != selectedYear) continue;
      if (expense.type.toUpperCase() != type) continue;

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

    final isFuture =
        newYear > now.year || (newYear == now.year && newMonth > now.month);

    if (isFuture) return;

    setState(() {
      selectedMonth = newMonth;
      selectedYear = newYear;
    });
  }

  String monthName(int month) {
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
    final monthExpense = getTotalForMonth(selectedMonth, 'EXPENSE');
    final monthIncome = getTotalForMonth(selectedMonth, 'INCOME');
    final monthSavings = monthIncome - monthExpense;

    final budgetUsed = monthlyBudget <= 0
        ? 0.0
        : (monthExpense / monthlyBudget).clamp(0.0, 1.0);

    final budgetLeft = monthlyBudget - monthExpense;

    final now = DateTime.now();
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    final daysLeft = selectedYear == now.year && selectedMonth == now.month
        ? daysInMonth - now.day
        : daysInMonth;

    final dailySafeSpend = daysLeft <= 0 ? 0.0 : budgetLeft / daysLeft;
    final savingsRate = monthIncome <= 0
        ? 0.0
        : (monthSavings / monthIncome).clamp(0.0, 1.0);

    final expenseCategories = getCategoryTotals(selectedMonth, 'EXPENSE');
    final incomeCategories = getCategoryTotals(selectedMonth, 'INCOME');

    final yearlyExpenses = getYearlyTotals('EXPENSE');
    final yearlyIncome = getYearlyTotals('INCOME');
    final yearlySavings = yearlyIncome.map(
      (month, income) => MapEntry(month, income - yearlyExpenses[month]!),
    );

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Insights',
          style: TextStyle(color: kInk, fontWeight: FontWeight.w800),
        ),
        actions: [
          _MonthSelector(
            month: selectedMonth,
            year: selectedYear,
            onChanged: changeMonth,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Monthly report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded),
            color: kInk,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
              ),
            )
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: loadExpenses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _SavingsHero(
                    monthName: monthName(selectedMonth),
                    year: selectedYear,
                    savings: monthSavings,
                    savingsRate: savingsRate,
                    expense: monthExpense,
                    budget: monthlyBudget,
                    budgetUsed: budgetUsed,
                    onEditBudget: openBudgetSheet,
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Budget left',
                          value: money(budgetLeft),
                          icon: Icons.account_balance_wallet_rounded,
                          color: budgetLeft >= 0 ? kIncomeColor : kExpenseColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Safe daily spend',
                          value: money(dailySafeSpend),
                          icon: Icons.today_rounded,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  _SpendingHeader(
                    title: 'Spending breakdown',
                    amount: monthExpense,
                    subtitle: expenseCategories.isEmpty
                        ? 'No expenses recorded this month'
                        : 'Ranked from highest to lowest',
                  ),
                  const SizedBox(height: 14),

                  if (expenseCategories.isEmpty)
                    _EmptyCard(
                      icon: Icons.receipt_long_rounded,
                      message: 'No expenses this month',
                    )
                  else
                    _RankedCategoryPanel(
                      categories: expenseCategories,
                      total: monthExpense,
                      colors: categoryColors,
                      isIncome: false,
                      selectedMonth: selectedMonth,
                      monthExpenses: getMonthExpenses(selectedMonth),
                    ),

                  const SizedBox(height: 28),

                  _SpendingHeader(
                    title: 'Income sources',
                    amount: monthIncome,
                    subtitle: incomeCategories.isEmpty
                        ? 'No income recorded this month'
                        : 'Ranked from highest to lowest',
                  ),
                  const SizedBox(height: 14),

                  if (incomeCategories.isEmpty)
                    _EmptyCard(
                      icon: Icons.savings_rounded,
                      message: 'No income this month',
                    )
                  else
                    _RankedCategoryPanel(
                      categories: incomeCategories,
                      total: monthIncome,
                      colors: categoryColors,
                      isIncome: true,
                      selectedMonth: selectedMonth,
                      monthExpenses: getMonthExpenses(selectedMonth),
                    ),

                  const SizedBox(height: 28),

                  _Panel(
                    title: 'Cash flow',
                    subtitle: 'Tap any month to explore income and spending',
                    child: _CashFlowChart(
                      income: yearlyIncome,
                      expense: yearlyExpenses,
                      savings: yearlySavings,
                      selectedMonth: selectedMonth,
                      onSelectMonth: (month) {
                        if (month == null) return;

                        final isFuture =
                            selectedYear > now.year ||
                            (selectedYear == now.year && month > now.month);

                        if (isFuture) return;

                        setState(() {
                          selectedMonth = month;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  _Panel(
                    title: 'Yearly pattern',
                    subtitle: 'Switch between expenses, income and savings',
                    child: _YearlyPattern(
                      expenses: yearlyExpenses,
                      income: yearlyIncome,
                      savings: yearlySavings,
                      selectedMetric: selectedMetric,
                      onMetricChanged: (value) {
                        setState(() {
                          selectedMetric = value;
                        });
                      },
                      colors: categoryColors,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<int> onChanged;

  const _MonthSelector({
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => onChanged(-1),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              key: ValueKey('$month-$year'),
              '${months[month - 1]} $year',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.chevron_right_rounded,
            onTap: isCurrentMonth ? null : () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? Colors.grey.shade400 : kPrimary,
        ),
      ),
    );
  }
}

class _SavingsHero extends StatelessWidget {
  final String monthName;
  final int year;
  final double savings;
  final double savingsRate;
  final double expense;
  final double budget;
  final double budgetUsed;
  final VoidCallback onEditBudget;

  const _SavingsHero({
    required this.monthName,
    required this.year,
    required this.savings,
    required this.savingsRate,
    required this.expense,
    required this.budget,
    required this.budgetUsed,
    required this.onEditBudget,
  });

  Color get budgetColor {
    if (budgetUsed >= 1) return const Color(0xFFFF6B6B);
    if (budgetUsed >= 0.8) return const Color(0xFFFFD166);
    return const Color(0xFFB9F6E4);
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = savings >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? const [Color(0xFF0B5D57), Color(0xFF0F766E), Color(0xFF14B8A6)]
              : const [Color(0xFF991B1B), Color(0xFFDC2626), Color(0xFFEF4444)],
        ),
        boxShadow: [
          BoxShadow(
            color: isPositive
                ? kPrimary.withValues(alpha: 0.30)
                : const Color(0xFFDC2626).withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 20),
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
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$monthName $year',
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
              GestureDetector(
                onTap: onEditBudget,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            isPositive ? 'NET SAVINGS' : 'MONTHLY DEFICIT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${savings.abs().toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isPositive
                        ? '${(savingsRate * 100).toStringAsFixed(1)}% saved'
                        : 'Over budget',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Budget usage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '₹${expense.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: budgetUsed,
                    minHeight: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: AlwaysStoppedAnimation(budgetColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget > 0
                          ? '${(budgetUsed * 100).toStringAsFixed(0)}% used'
                          : 'Set a budget',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      budget > 0
                          ? '₹${(budget - expense).toStringAsFixed(0)} left'
                          : 'Tap to add',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
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

class _SpendingHeader extends StatelessWidget {
  final String title;
  final double amount;
  final String subtitle;

  const _SpendingHeader({
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: kInk,
          ),
        ),
      ],
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

class _RankedCategoryPanel extends StatelessWidget {
  final Map<String, double> categories;
  final double total;
  final List<Color> colors;
  final bool isIncome;
  final int selectedMonth;
  final List<Expense> monthExpenses;

  const _RankedCategoryPanel({
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
    final accent = isIncome ? kIncomeColor : kExpenseColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: entries.length <= 7
          ? Column(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _CategoryRow(
                    rank: index + 1,
                    title: entries[index].key,
                    amount: entries[index].value,
                    percentage: total == 0 ? 0 : entries[index].value / total,
                    color: colors[index % colors.length],
                    accent: accent,
                    onTap: () => _openDetails(context, entries[index].key),
                  ),
              ],
            )
          : SizedBox(
              height: 560,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];

                  return _CategoryRow(
                    rank: index + 1,
                    title: entry.key,
                    amount: entry.value,
                    percentage: total == 0 ? 0 : entry.value / total,
                    color: colors[index % colors.length],
                    accent: accent,
                    onTap: () => _openDetails(context, entry.key),
                  );
                },
              ),
            ),
    );
  }

  void _openDetails(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailsScreen(
          category: category,
          month: selectedMonth,
          expenses: monthExpenses,
          isIncome: isIncome,
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int rank;
  final String title;
  final double amount;
  final double percentage;
  final Color color;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.rank,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.72)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}% of total',
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final Map<int, double> income;
  final Map<int, double> expense;
  final Map<int, double> savings;
  final int selectedMonth;
  final ValueChanged<int?> onSelectMonth;

  const _CashFlowChart({
    required this.income,
    required this.expense,
    required this.savings,
    required this.selectedMonth,
    required this.onSelectMonth,
  });

  List<FlSpot> spots(Map<int, double> data) {
    return List.generate(12, (index) {
      return FlSpot(index.toDouble(), data[index + 1] ?? 0);
    });
  }

  LineChartBarData areaLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      preventCurveOverShooting: true,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ),
      ),
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _maxY();

    return Column(
      children: [
        Row(
          children: [
            _Legend(color: kIncomeColor, label: 'Income'),
            const SizedBox(width: 16),
            _Legend(color: kExpenseColor, label: 'Expenses'),
            const SizedBox(width: 16),
            _Legend(color: kPrimarySoft, label: 'Savings'),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: kBorder, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: kBorder),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      const letters = [
                        'J',
                        'F',
                        'M',
                        'A',
                        'M',
                        'J',
                        'J',
                        'A',
                        'S',
                        'O',
                        'N',
                        'D',
                      ];

                      final index = value.toInt();

                      if (index < 0 || index > 11) {
                        return const SizedBox.shrink();
                      }

                      final isSelected = selectedMonth == index + 1;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          letters[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelected
                                ? kPrimary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => kInk,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      final isExpense = spot.barIndex == 1;

                      final label = isIncome
                          ? 'Income'
                          : isExpense
                          ? 'Expense'
                          : 'Savings';

                      final color = isIncome
                          ? const Color(0xFF34D399)
                          : isExpense
                          ? const Color(0xFFFB7185)
                          : kPrimarySoft;

                      return LineTooltipItem(
                        '$label\n₹${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      );
                    }).toList();
                  },
                ),
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;

                  if (response == null || response.lineBarSpots == null) {
                    onSelectMonth(null);
                    return;
                  }

                  onSelectMonth(response.lineBarSpots!.first.x.toInt() + 1);
                },
              ),
              lineBarsData: [
                areaLine(spots(income), kIncomeColor),
                areaLine(spots(expense), kExpenseColor),
                areaLine(spots(savings), kPrimarySoft),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _maxY() {
    double maxValue = 0;

    for (var month = 1; month <= 12; month++) {
      maxValue = max(maxValue, income[month] ?? 0);
      maxValue = max(maxValue, expense[month] ?? 0);
      maxValue = max(maxValue, (savings[month] ?? 0).abs());
    }

    if (maxValue == 0) return 100;

    return maxValue * 1.25;
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _YearlyPattern extends StatelessWidget {
  final Map<int, double> expenses;
  final Map<int, double> income;
  final Map<int, double> savings;
  final String selectedMetric;
  final ValueChanged<String> onMetricChanged;
  final List<Color> colors;

  const _YearlyPattern({
    required this.expenses,
    required this.income,
    required this.savings,
    required this.selectedMetric,
    required this.onMetricChanged,
    required this.colors,
  });

  Map<int, double> get data {
    if (selectedMetric == 'Income') return income;
    if (selectedMetric == 'Savings') return savings;
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((entry) => entry.value > 0).toList();

    final total = data.values.fold<double>(0, (sum, value) => sum + value);

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
        Row(
          children: [
            _MetricTab(
              label: 'Expenses',
              isSelected: selectedMetric == 'Expenses',
              color: kExpenseColor,
              onTap: () => onMetricChanged('Expenses'),
            ),
            const SizedBox(width: 8),
            _MetricTab(
              label: 'Income',
              isSelected: selectedMetric == 'Income',
              color: kIncomeColor,
              onTap: () => onMetricChanged('Income'),
            ),
            const SizedBox(width: 8),
            _MetricTab(
              label: 'Savings',
              isSelected: selectedMetric == 'Savings',
              color: kPrimary,
              onTap: () => onMetricChanged('Savings'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'No $selectedMetric data this year',
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
                          touchCallback: (event, response) {},
                        ),
                        sections: entries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final amount = entry.value.value;
                          final color = colors[index % colors.length];

                          return PieChartSectionData(
                            value: amount,
                            color: color,
                            radius: 66,
                            cornerRadius: 14,
                            title:
                                '${(amount / total * 100).toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Total $selectedMetric',
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: kInk,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
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
          children: entries.map((entry) {
            final index = entries.indexOf(entry);
            final color = colors[index % colors.length];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
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
                    months[entry.key - 1],
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MetricTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MetricTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color : kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : kMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({required this.icon, required this.message});

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
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
