import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/eh_card.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'transactions_screen.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import 'group_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Expense>? onTransactionSelected;
  final VoidCallback? onOpenGroups;
  final VoidCallback? onOpenTransactions;

  const HomeScreen({
    super.key,
    this.onTransactionSelected,
    this.onOpenGroups,
    this.onOpenTransactions,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  final ExpenseService expenseService = ExpenseService();
  final GroupService groupService = GroupService();

  List<Group> groups = [];
  bool isLoadingGroups = true;

  ValueChanged<Expense>? get onTransactionSelected =>
      widget.onTransactionSelected;

  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;
  String userName = '';

  VoidCallback? get onOpenGroups => widget.onOpenGroups;
  VoidCallback? get onOpenTransactions => widget.onOpenTransactions;

  String selectedRange = 'Month';

  @override
  void initState() {
    super.initState();
    loadUserName();
    loadExpenses();
    loadGroups();
  }

  void refreshUserName() {
    loadUserName();
  }

  void openGroupsScreen() {
    if (onOpenGroups != null) {
      onOpenGroups!();
    }
  }

  void openGroupDetails(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
    );
  }

  String _groupSubtitle(Group group) {
    return 'Tap to view';
  }

  Future<void> loadGroups() async {
    setState(() {
      isLoadingGroups = true;
    });

    try {
      final result = await groupService.getGroups();

      if (!mounted) return;

      setState(() {
        groups = result;
        isLoadingGroups = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        groups = [];
        isLoadingGroups = false;
      });
    }
  }

  Future<void> loadUserName() async {
    try {
      final name = await authService.getUserName();

      if (!mounted) return;

      setState(() {
        userName = name ?? 'User';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        userName = 'User';
      });
    }
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

  List<Expense> getRangeExpenses() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (selectedRange == 'Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else if (selectedRange == 'Year') {
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year + 1, 1, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    }

    return expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);
      if (date == null) return false;

      return !date.isBefore(startDate) && date.isBefore(endDate);
    }).toList();
  }

  Map<String, double> getTotals() {
    final rangeExpenses = getRangeExpenses();

    double income = 0;
    double expenseTotal = 0;

    for (final expense in rangeExpenses) {
      if (expense.type.toUpperCase() == 'INCOME') {
        income += expense.amount;
      } else {
        expenseTotal += expense.amount;
      }
    }

    return {
      'income': income,
      'expense': expenseTotal,
      'balance': income - expenseTotal,
    };
  }

  List<Expense> getRecentTransactions() {
    final sorted = List<Expense>.from(expenses);

    sorted.sort((a, b) {
      final timeA = DateTime.tryParse(a.createdAt ?? a.date);
      final timeB = DateTime.tryParse(b.createdAt ?? b.date);

      if (timeA == null || timeB == null) return 0;

      return timeB.compareTo(timeA);
    });

    return sorted.take(4).toList();
  }

  void openTransactions(String filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionsScreen(
          initialFilter: filter,
          initialRange: selectedRange,
        ),
      ),
    );
  }

  void openAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  Future<void> openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    loadExpenses();
  }

  Future<void> openAddIncome() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
    loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final totals = getTotals();
    final recentTransactions = getRecentTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: loadExpenses,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoWidth = MediaQuery.of(context).size.width * 0.10;

                  return Image.asset(
                    'assets/images/logo.png',
                    width: logoWidth.clamp(145.0, 160.0),
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : RefreshIndicator(
              onRefresh: loadExpenses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _greeting(),
                  const SizedBox(height: 4),
                  _balanceCard(totals),
                  AppSpacing.gapLg,
                  _quickActions(),
                  AppSpacing.gapLg,
                  _sectionHeader(
                    title: 'Recent transactions',
                    actionText: 'See all',
                    onAction: () {
                      if (onOpenTransactions != null) {
                        onOpenTransactions!();
                      } else {
                        openAllTransactions();
                      }
                    },
                  ),
                  AppSpacing.gapSm,
                  if (recentTransactions.isEmpty)
                    _emptyRecent()
                  else
                    ...recentTransactions.map(_recentTile),
                  AppSpacing.gapLg,
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Groups',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  isLoadingGroups
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : groups.isEmpty
                      ? _emptyGroups()
                      : _groupsPreview(groups.take(3).toList()),
                ],
              ),
            ),
    );
  }

  Widget _greeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        '$greeting, $userName',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _balanceCard(Map<String, double> totals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _rangeSelector(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹${totals['balance']!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  label: 'Income',
                  amount: totals['income']!,
                  icon: Icons.trending_up,
                  onTap: () => openTransactions('INCOME'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _balanceStat(
                  label: 'Expenses',
                  amount: totals['expense']!,
                  icon: Icons.trending_down,
                  onTap: () => openTransactions('EXPENSE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Week', 'Month', 'Year'].map((range) {
          final isSelected = selectedRange == range;

          return GestureDetector(
            onTap: () => setState(() => selectedRange = range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                range,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _balanceStat({
    required String label,
    required double amount,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickCard(
            title: 'Add Expense',
            subtitle: 'Track spending',
            icon: Icons.add_circle_outline,
            gradient: const [Color(0xFFFFE4E6), Color(0xFFFFD5DA)],
            iconColor: const Color(0xFFE11D48),
            onTap: openAddExpense,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _quickCard(
            title: 'Add Income',
            subtitle: 'Add earnings',
            icon: Icons.savings_outlined,
            gradient: const [Color(0xFFDCFCE7), Color(0xFFC8F5D6)],
            iconColor: const Color(0xFF059669),
            onTap: openAddIncome,
          ),
        ),
      ],
    );
  }

  Widget _quickCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _groupsPreview(List<Group> groups) {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length + 1,
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return _openGroupsChip();
          }

          final group = groups[index];

          return GestureDetector(
            onTap: () => openGroupDetails(group),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.group_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _groupSubtitle(group),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _openGroupsChip() {
    return GestureDetector(
      onTap: openGroupsScreen,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_2, color: AppColors.primary),
              const SizedBox(height: 8),
              const Text(
                'All Groups',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentTile(Expense expense) {
    final isIncome = expense.type.toUpperCase() == 'INCOME';
    final color = isIncome
        ? const Color.fromARGB(255, 10, 146, 100)
        : const Color.from(alpha: 1, red: 0.937, green: 0.267, blue: 0.267);

    final String title = expense.description;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (onTransactionSelected != null) {
            onTransactionSelected!(expense);
          } else {
            openAllTransactions();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 20,
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expense.category ?? 'Uncategorized',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyRecent() {
    return EhCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.textSecondary),
          AppSpacing.gapSm,
          const Text(
            'No recent transactions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyGroups() {
    return GestureDetector(
      onTap: openGroupsScreen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.group_add, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a group',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Split expenses with friends or family.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
