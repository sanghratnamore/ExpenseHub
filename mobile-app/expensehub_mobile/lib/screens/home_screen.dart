import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';
import 'add_transaction_screen.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'account_information_screen.dart';
import 'change_password_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Expense>? onTransactionSelected;

  const HomeScreen({super.key, this.onTransactionSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authService = AuthService();
  final expenseService = ExpenseService();

  String userName = 'User';
  String userEmail = '';

  List<Expense> allExpenses = [];
  bool isLoading = true;
  String? errorMessage;

  String selectedPeriod = 'Month';

  @override
  void initState() {
    super.initState();
    loadUser();
    loadExpenses();
  }

  Future<void> loadUser() async {
    final name = await authService.getUserName();
    final email = await authService.getUserEmail();

    if (!mounted) return;

    setState(() {
      userName = name ?? 'User';
      userEmail = email ?? '';
    });
  }

  Future<void> loadExpenses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final expenses = await expenseService.getExpenses();

      if (!mounted) return;

      setState(() {
        allExpenses = expenses;
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

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> openAddExpense() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (added == true) {
      loadExpenses();
    }
  }

  Future<void> openAddIncome() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
    );

    if (added == true) {
      loadExpenses();
    }
  }

  Future<void> openAddTransaction(String type) async {
    if (type.toUpperCase() == 'INCOME') {
      await openAddIncome();
    } else {
      await openAddExpense();
    }
  }

  Future<void> openProfile() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(userEmail),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account information'),
                onTap: () async {
                  Navigator.pop(context);

                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountInformationScreen(),
                    ),
                  );

                  if (updated == true) {
                    loadUser();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Password change'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await authService.logout();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Expense> getExpensesForPeriod() {
    final now = DateTime.now();

    if (selectedPeriod == 'Week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      return allExpenses.where((expense) {
        final date = DateTime.tryParse(expense.date);
        if (date == null) return false;

        return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(weekEnd);
      }).toList();
    }

    if (selectedPeriod == 'Year') {
      return allExpenses.where((expense) {
        final date = DateTime.tryParse(expense.date);
        if (date == null) return false;

        return date.year == now.year;
      }).toList();
    }

    return allExpenses.where((expense) {
      final date = DateTime.tryParse(expense.date);
      if (date == null) return false;

      return date.year == now.year && date.month == now.month;
    }).toList();
  }

  Map<String, double> calculateTotals(List<Expense> expenses) {
    double income = 0;
    double expenseTotal = 0;

    for (final expense in expenses) {
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

  @override
  Widget build(BuildContext context) {
    final periodExpenses = getExpensesForPeriod();
    final totals = calculateTotals(periodExpenses);

    final recentExpenses = List<Expense>.from(periodExpenses)
      ..sort((a, b) {
        final timeA = DateTime.tryParse(a.createdAt ?? a.date);

        final timeB = DateTime.tryParse(b.createdAt ?? b.date);

        if (timeA == null || timeB == null) return 0;

        return timeB.compareTo(timeA);
      });
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadExpenses,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        loadExpenses();
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: openProfile,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$selectedPeriod Balance',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totals['balance']!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Income',
                              amount: totals['income']!,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              title: 'Expense',
                              amount: totals['expense']!,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PeriodTab(
                            label: 'W',
                            isSelected: selectedPeriod == 'Week',
                            onTap: () {
                              setState(() {
                                selectedPeriod = 'Week';
                              });
                            },
                          ),
                          PeriodTab(
                            label: 'M',
                            isSelected: selectedPeriod == 'Month',
                            onTap: () {
                              setState(() {
                                selectedPeriod = 'Month';
                              });
                            },
                          ),
                          PeriodTab(
                            label: 'Y',
                            isSelected: selectedPeriod == 'Year',
                            onTap: () {
                              setState(() {
                                selectedPeriod = 'Year';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => openAddTransaction('EXPENSE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade500, Colors.red.shade700],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_card,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add Expense',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => openAddTransaction('INCOME'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade500,
                            Colors.green.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.savings,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add Income',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 42,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No transactions for this $selectedPeriod',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...recentExpenses.take(5).map((expense) {
                final isIncome = expense.type.toUpperCase() == 'INCOME';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      if (widget.onTransactionSelected != null) {
                        widget.onTransactionSelected!(expense);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      expense.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${expense.category} • ${expense.date}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          child: expense.isRecurring
                              ? Icon(
                                  Icons.repeat,
                                  size: 16,
                                  color: Colors.teal.shade700,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(2)}',
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
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PeriodTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.teal.shade800,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
