import 'package:flutter/material.dart';

import '../services/expense_service.dart';
import '../models/expense.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_sheet.dart';

import 'package:intl/intl.dart';

import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final expenseService = ExpenseService();
  final searchController = TextEditingController();
  String searchQuery = '';
  List<Expense> expenses = [];
  bool isLoading = true;
  String? errorMessage;

  String selectedFilter = 'All';
  DateTime selectedMonth = DateTime.now();

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

  List<Expense> getFilteredExpenses() {
    List<Expense> result;

    if (selectedFilter == 'Income') {
      result = expenses.where((e) => e.type.toUpperCase() == 'INCOME').toList();
    } else if (selectedFilter == 'Expense') {
      result = expenses.where((e) => e.type.toUpperCase() != 'INCOME').toList();
    } else {
      result = List<Expense>.from(expenses);
    }

    final monthTransactions = result.where((expense) {
      final date = DateTime.tryParse(expense.date);
      if (date == null) return false;

      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    final query = searchQuery.trim().toLowerCase();

    final filteredTransactions = query.isEmpty
        ? monthTransactions
        : monthTransactions.where((expense) {
            final description = expense.description.toLowerCase();

            return description.contains(query);
          }).toList();

    filteredTransactions.sort((a, b) {
      final timeA = DateTime.tryParse(a.createdAt ?? a.date);

      final timeB = DateTime.tryParse(b.createdAt ?? b.date);

      if (timeA == null || timeB == null) return 0;

      return timeB.compareTo(timeA);
    });

    return filteredTransactions;
  }

  List<String> getSearchSuggestions(String query) {
    final queryLower = query.trim().toLowerCase();

    if (queryLower.isEmpty) return [];

    final words = <String>{};

    for (final expense in expenses) {
      final text = [
        expense.description,
        expense.category,
        expense.type,
        expense.date,
        expense.amount.toString(),
      ].join(' ');

      for (final word in text.split(RegExp(r'\s+'))) {
        final cleanWord = word.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

        if (cleanWord.length < 2) continue;

        if (cleanWord.contains(queryLower)) {
          words.add(cleanWord);
        }
      }
    }

    final suggestions = words.toList();

    suggestions.sort((a, b) {
      final aStarts = a.startsWith(queryLower);
      final bStarts = b.startsWith(queryLower);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return a.compareTo(b);
    });

    return suggestions.take(8).toList();
  }

  Future<void> openTransaction(Expense expense) async {
    await showTransactionDetailsSheet(
      context: context,
      expense: expense,
      onChanged: loadExpenses,
    );
  }

  Future<void> deleteTransaction(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text('This transaction will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await expenseService.deleteExpense(expense.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transaction deleted')));

      loadExpenses();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = getFilteredExpenses();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transactions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedFilter == 'All',
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Income'),
                        selected: selectedFilter == 'Income',
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = 'Income';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Expense'),
                        selected: selectedFilter == 'Expense',
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = 'Expense';
                          });
                        },
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedMonth,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDatePickerMode: DatePickerMode.year,
                          );

                          if (picked != null) {
                            setState(() {
                              selectedMonth = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM yyyy').format(selectedMonth),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? const Center(child: Text('No transactions found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];
                            final isIncome =
                                expense.type.toUpperCase() == 'INCOME';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => openTransaction(expense),
                                leading: CircleAvatar(
                                  backgroundColor: isIncome
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  expense.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${expense.category} • ${expense.date}',
                                ),
                                trailing: Text(
                                  '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
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

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const DetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
