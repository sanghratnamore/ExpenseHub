import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/eh_card.dart';
import 'transaction_details_sheet.dart';
import '../widgets/eh_search_bar.dart';

class TransactionListScreen extends StatefulWidget {
  final String type; // 'INCOME' or 'EXPENSE'

  const TransactionListScreen({super.key, required this.type});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final ExpenseService expenseService = ExpenseService();
  final TextEditingController searchController = TextEditingController();

  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';

  bool get isIncome => widget.type.toUpperCase() == 'INCOME';

  Color get accentColor => isIncome ? AppColors.income : AppColors.expense;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  List<Expense> getTransactions() {
    final now = DateTime.now();

    final monthTransactions = expenses.where((expense) {
      final date = DateTime.tryParse(expense.date);
      if (date == null) return false;

      final matchesType = isIncome
          ? expense.type.toUpperCase() == 'INCOME'
          : expense.type.toUpperCase() != 'INCOME';

      final matchesMonth = date.year == now.year && date.month == now.month;

      return matchesType && matchesMonth;
    }).toList();

    monthTransactions.sort((a, b) {
      final timeA = DateTime.tryParse(a.createdAt ?? a.date);
      final timeB = DateTime.tryParse(b.createdAt ?? b.date);

      if (timeA == null || timeB == null) return 0;

      return timeB.compareTo(timeA);
    });

    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return monthTransactions;

    return monthTransactions.where((expense) {
      final text = [
        expense.description,
        expense.category,
        expense.amount.toString(),
        expense.date,
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();
  }

  Map<String, List<Expense>> groupByDate(List<Expense> transactions) {
    final groups = <String, List<Expense>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final expense in transactions) {
      final date = DateTime.tryParse(expense.date);
      if (date == null) continue;

      final expenseDate = DateTime(date.year, date.month, date.day);
      String label;

      if (expenseDate == today) {
        label = 'Today';
      } else if (expenseDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, d MMM').format(expenseDate);
      }

      groups.putIfAbsent(label, () => []).add(expense);
    }

    return groups;
  }

  double getTotal(List<Expense> transactions) {
    double total = 0;

    for (final expense in transactions) {
      total += expense.amount;
    }

    return total;
  }

  Future<void> openTransaction(Expense expense) async {
    await showTransactionDetailsSheet(
      context: context,
      expense: expense,
      onChanged: loadExpenses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = getTransactions();
    final total = getTotal(transactions);
    final groupedTransactions = groupByDate(transactions);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isIncome ? 'Income Transactions' : 'Expense Transactions',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Text(errorMessage!),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadExpenses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _header(total, transactions.length),
                  AppSpacing.gapLg,
                  EhSearchBar(
                    controller: searchController,
                    hintText: 'Search transactions...',
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onClear: () {
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  ),
                  AppSpacing.gapLg,
                  if (transactions.isEmpty)
                    _emptyState()
                  else
                    ...groupedTransactions.entries.map(
                      (entry) => _dateGroup(
                        label: entry.key,
                        transactions: entry.value,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _header(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isIncome
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFFDC2626), const Color(0xFFF97316)],
        ),
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIncome ? 'Total income' : 'Total expenses',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('MMMM yyyy').format(DateTime.now())} • $count transactions',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  
  Widget _emptyState() {
    return EhCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.savings : Icons.receipt_long,
              size: 34,
              color: accentColor,
            ),
          ),
          AppSpacing.gapMd,
          Text(
            isIncome ? 'No income transactions' : 'No expense transactions',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another search or add a new transaction.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateGroup({
    required String label,
    required List<Expense> transactions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...transactions.map(_transactionTile),
        AppSpacing.gapMd,
      ],
    );
  }

  Widget _transactionTile(Expense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EhCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => openTransaction(expense),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: accentColor,
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.category ?? '',
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
              '₹${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
