
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ExpenseService expenseService = ExpenseService();

  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadExpenses();
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

  List<Expense> expensesForMonth(int month, int year) {
    return expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);
      return date?.year == year && date?.month == month;
    }).toList();
  }

  double totalForMonth(int month, int year, String type) {
    double total = 0;

    for (final expense in expensesForMonth(month, year)) {
      if (expense.type.toUpperCase() == type) {
        total += expense.amount;
      }
    }

    return total;
  }

  Map<String, double> categoryTotals(int month, int year) {
    final totals = <String, double>{};

    for (final expense in expensesForMonth(month, year)) {
      if (expense.type.toUpperCase() != 'EXPENSE') continue;

      final category = expense.category ?? 'Other';
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }

  Map<int, double> monthlyTotals(String type, int monthsBack) {
    final anchor = DateTime(selectedYear, selectedMonth);
    final data = <int, double>{};

    for (var i = monthsBack - 1; i >= 0; i--) {
      final date = DateTime(anchor.year, anchor.month - i);
      final key = date.year * 100 + date.month;

      data[key] = totalForMonth(date.month, date.year, type);
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

  Color savingsColor(double rate) {
    if (rate < 0) return const Color(0xFFEF4444);
    if (rate < 15) return const Color(0xFFF59E0B);
    if (rate < 30) return const Color(0xFF0F766E);
    return const Color(0xFF10B981);
  }

  String savingsLabel(double rate) {
    if (rate < 0) return 'Overspending';
    if (rate < 15) return 'Needs attention';
    if (rate < 30) return 'Good';
    return 'Excellent';
  }

  @override
  Widget build(BuildContext context) {
    final income = totalForMonth(selectedMonth, selectedYear, 'INCOME');
    final expense = totalForMonth(selectedMonth, selectedYear, 'EXPENSE');
    final savings = income - expense;

    final savingsRate = income > 0 ? (savings / income) * 100 : 0.0;

    final previousDate = DateTime(selectedYear, selectedMonth - 1);
    final previousExpense =
        totalForMonth(previousDate.month, previousDate.year, 'EXPENSE');
    final previousIncome =
        totalForMonth(previousDate.month, previousDate.year, 'INCOME');

    final previousSavings = previousIncome - previousExpense;
    final previousRate =
        previousIncome > 0 ? (previousSavings / previousIncome) * 100 : 0.0;

    final expenseChange = previousExpense > 0
        ? ((expense - previousExpense) / previousExpense) * 100
        : 0.0;

    final currentCategories = categoryTotals(selectedMonth, selectedYear);
    final previousCategories =
        categoryTotals(previousDate.month, previousDate.year);

    final changes = <MapEntry<String, double>>[];

    for (final entry in currentCategories.entries) {
      final previous = previousCategories[entry.key] ?? 0;
      changes.add(MapEntry(entry.key, entry.value - previous));
    }

    changes.sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final topChanges = changes.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Financial Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
       actions: const [],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(errorMessage!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadExpenses,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      _monthSelector(),
                      const SizedBox(height: 18),
                      _reportHeader(
                        income: income,
                        expense: expense,
                        savings: savings,
                        savingsRate: savingsRate,
                        expenseChange: expenseChange,
                      ),
                      const SizedBox(height: 18),
                      _insightCards(
                        savingsRate: savingsRate,
                        previousRate: previousRate,
                        expenseChange: expenseChange,
                        topCategory:
                            currentCategories.keys.isNotEmpty
                                ? currentCategories.keys.first
                                : null,
                      ),
                      const SizedBox(height: 22),
                      _trendCard(),
                      const SizedBox(height: 22),
                      _changesCard(topChanges),
                    ],
                  ),
                ),
    );
  }

  Widget _monthSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.chevron_left,
            onTap: () => changeMonth(-1),
          ),
          Expanded(
            child: Text(
              '${monthName(selectedMonth)} $selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _iconButton(
            icon: Icons.chevron_right,
            onTap: () => changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _reportHeader({
    required double income,
    required double expense,
    required double savings,
    required double savingsRate,
    required double expenseChange,
  }) {
    final isSaving = savings >= 0;
    final color = savingsColor(savingsRate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSaving
              ? [const Color(0xFF0F172A), const Color(0xFF134E4A)]
              : [const Color(0xFF7F1D1D), const Color(0xFFB45309)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 12),
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
                      '${monthName(selectedMonth)} report',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${savings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savings >= 0 ? 'Net savings' : 'Net deficit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        savingsLabel(savingsRate),
                        style: TextStyle(
                          color: color == const Color(0xFFEF4444)
                              ? Colors.red.shade100
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _savingsRing(savingsRate),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _headerStat(
                label: 'Income',
                value: '₹${income.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 10),
              _headerStat(
                label: 'Expenses',
                value: '₹${expense.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _savingsRing(double rate) {
    final color = savingsColor(rate);
    final normalizedRate = (rate / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: normalizedRate,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'saved',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightCards({
    required double savingsRate,
    required double previousRate,
    required double expenseChange,
    String? topCategory,
  }) {
    final insights = <MapEntry<IconData, String>>[];

    if (topCategory != null) {
      insights.add(
        MapEntry(
          Icons.category,
          'Your largest expense category was $topCategory.',
        ),
      );
    }

    if (expenseChange > 0) {
      insights.add(
        MapEntry(
          Icons.trending_up,
          'You spent ${expenseChange.toStringAsFixed(1)}% more than last month.',
        ),
      );
    } else if (expenseChange < 0) {
      insights.add(
        MapEntry(
          Icons.trending_down,
          'You spent ${expenseChange.abs().toStringAsFixed(1)}% less than last month.',
        ),
      );
    }

    if (savingsRate > previousRate) {
      insights.add(
        MapEntry(
          Icons.savings,
          'Your savings rate improved from '
              '${previousRate.toStringAsFixed(1)}% to '
              '${savingsRate.toStringAsFixed(1)}%.',
        ),
      );
    } else if (savingsRate < previousRate) {
      insights.add(
        MapEntry(
          Icons.warning_amber_rounded,
          'Your savings rate fell from '
              '${previousRate.toStringAsFixed(1)}% to '
              '${savingsRate.toStringAsFixed(1)}%.',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const MapEntry(
          Icons.info_outline,
          'Add income and expense transactions to generate insights.',
        ),
      );
    }

    return Column(
      children: insights.take(3).map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  insight.key,
                  size: 18,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  insight.value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _trendCard() {
    final incomeData = monthlyTotals('INCOME', 6);
    final expenseData = monthlyTotals('EXPENSE', 6);
    final keys = incomeData.keys.toList();

    return _reportCard(
      title: 'Money flow',
      subtitle: 'Income compared with expenses over 6 months',
      child: Column(
        children: [
          Row(
            children: [
              _legendDot(
                color: const Color(0xFF10B981),
                label: 'Income',
              ),
              const SizedBox(width: 18),
              _legendDot(
                color: const Color(0xFFEF4444),
                label: 'Expenses',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= keys.length) {
                          return const SizedBox.shrink();
                        }

                        final key = keys[index];
                        final month = key % 100;

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortMonth(month),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots(incomeData),
                    isCurved: true,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF34D399),
                      ],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.25),
                          const Color(0xFF10B981).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: _spots(expenseData),
                    isCurved: true,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEF4444),
                        const Color(0xFFF97316),
                      ],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.20),
                          const Color(0xFFEF4444).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final isIncome = spot.barIndex == 0;

                      return LineTooltipItem(
                        '${isIncome ? 'Income' : 'Expense'}\n₹${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _spots(Map<int, double> data) {
    final keys = data.keys.toList();

    return List.generate(keys.length, (index) {
      return FlSpot(index.toDouble(), data[keys[index]] ?? 0);
    });
  }

  Widget _changesCard(List<MapEntry<String, double>> changes) {
    return _reportCard(
      title: 'Biggest category changes',
      subtitle: 'Compared with last month',
      child: changes.isEmpty
          ? Text(
              'No expense data available for comparison.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Column(
              children: changes.map((change) {
                final increased = change.value > 0;
                final color = increased
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          increased
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              change.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              increased
                                  ? 'Spending increased'
                                  : 'Spending decreased',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${increased ? '+' : '-'}₹${change.value.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _reportCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}