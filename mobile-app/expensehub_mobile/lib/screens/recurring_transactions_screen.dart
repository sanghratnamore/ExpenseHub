import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'recurring_transaction_details_sheet.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final recurringService = RecurringTransactionService();

  List<RecurringTransaction> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  final Set<String> _selectedTransactionIds = {};

  bool get _isSelectionMode =>
      _selectedTransactionIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    loadRecurringTransactions();
  }

  Future<void> loadRecurringTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await recurringService
          .getRecurringTransactions();

      if (!mounted) return;

      result.sort((a, b) {
        final aDate =
            a.createdAt ?? a.startDate;
        final bDate =
            b.createdAt ?? b.startDate;

        return bDate.compareTo(aDate);
      });

      setState(() {
        transactions = result;
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

  void _toggleTransactionSelection(String id) {
    setState(() {
      if (_selectedTransactionIds.contains(id)) {
        _selectedTransactionIds.remove(id);
      } else {
        _selectedTransactionIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedTransactions() async {
    if (_selectedTransactionIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete selected recurring transactions?',
          ),
          content: Text(
            '${_selectedTransactionIds.length} recurring transaction(s) will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                  dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                  dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      for (final id in _selectedTransactionIds) {
        await recurringService
            .deleteRecurringTransaction(id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedTransactionIds.length} recurring transaction(s) deleted',
          ),
        ),
      );

      setState(() {
        _selectedTransactionIds.clear();
      });

      loadRecurringTransactions();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Delete failed: $error'),
        ),
      );
    }
  }

  Future<void> openAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(
          autoRecurring: true,
        ),
      ),
    );

    if (result == true) {
      loadRecurringTransactions();

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> openAddIncome() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddIncomeScreen(
          autoRecurring: true,
        ),
      ),
    );

    if (result == true) {
      loadRecurringTransactions();

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> openDetails(
    RecurringTransaction transaction,
  ) async {
    await showRecurringDetailsSheet(
      context: context,
      transaction: transaction,
      onChanged: () async {
        await loadRecurringTransactions();

        if (mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Recurring Transactions'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!),
                )
              : transactions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh:
                          loadRecurringTransactions,
                      child: Column(
                        children: [
                          if (_isSelectionMode)
                            _buildSelectionBar(),

                          Expanded(
                            child:
                                ListView.builder(
                              padding: const EdgeInsets
                                  .fromLTRB(
                                16,
                                16,
                                16,
                                120,
                              ),
                              itemCount: transactions
                                  .length,
                              itemBuilder:
                                  (context, index) {
                                final transaction =
                                    transactions[
                                        index];

                                final isIncome =
                                    transaction.type
                                            .toUpperCase() ==
                                        'INCOME';

                                final color =
                                    isIncome
                                        ? Colors.green
                                        : Colors.red;

                                final isSelected =
                                    _selectedTransactionIds
                                        .contains(
                                            transaction
                                                .id);

                                return GestureDetector(
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleTransactionSelection(
                                        transaction
                                            .id!,
                                      );
                                      return;
                                    }

                                    openDetails(
                                        transaction);
                                  },
                                  onLongPress: () {
                                    _toggleTransactionSelection(
                                      transaction
                                          .id!,
                                    );
                                  },
                                  child:
                                      AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds:
                                            180),
                                    margin: const EdgeInsets
                                        .only(
                                        bottom:
                                            12),
                                    padding:
                                        const EdgeInsets
                                            .all(
                                            16),
                                    decoration:
                                        BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue
                                              .shade50
                                          : Colors
                                              .white,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  20),
                                      border:
                                          Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                                .shade600
                                            : Colors
                                                .transparent,
                                        width: isSelected
                                            ? 1.6
                                            : 0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .black
                                              .withValues(
                                                  alpha:
                                                      0.05),
                                          blurRadius:
                                              14,
                                          offset:
                                              const Offset(
                                                  0,
                                                  5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        if (_isSelectionMode) ...[
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds:
                                                    180),
                                            width:
                                                24,
                                            height:
                                                24,
                                            alignment:
                                                Alignment
                                                    .center,
                                            decoration:
                                                BoxDecoration(
                                              color: isSelected
                                                  ? Colors
                                                      .blue
                                                      .shade600
                                                  : Colors
                                                      .white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      9),
                                              border:
                                                  Border.all(
                                                color: isSelected
                                                    ? Colors
                                                        .blue
                                                        .shade600
                                                    : Colors
                                                        .grey
                                                        .shade300,
                                                width:
                                                    1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons
                                                        .check_rounded,
                                                    size:
                                                        15,
                                                    color:
                                                        Colors.white,
                                                  )
                                                : const SizedBox
                                                    .shrink(),
                                          ),
                                          const SizedBox(
                                              width:
                                                  12),
                                        ],

                                        Container(
                                          width:
                                              44,
                                          height:
                                              44,
                                          alignment:
                                              Alignment
                                                  .center,
                                          decoration:
                                              BoxDecoration(
                                            color: color
                                                .withValues(
                                                    alpha:
                                                        0.12),
                                            shape:
                                                BoxShape
                                                    .circle,
                                          ),
                                          child:
                                              Icon(
                                            isIncome
                                                ? Icons
                                                    .arrow_downward
                                                : Icons
                                                    .arrow_upward,
                                            color:
                                                color,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                14),

                                        Expanded(
                                          child:
                                              Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                transaction
                                                    .title,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height:
                                                      4),
                                              Text(
                                                transaction
                                                        .active
                                                    ? '${transaction.frequency} • Next: ${DateFormat('dd MMM yyyy').format(transaction.nextDueDate)}'
                                                    : '${transaction.frequency} • Paused',
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      12,
                                                  color:
                                                      Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Text(
                                          '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                                          style:
                                              TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color:
                                                color,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                8),

                                        const Icon(
                                          Icons
                                              .chevron_right,
                                          color:
                                              Colors
                                                  .grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Add Expense',
                  icon:
                      Icons.shopping_bag_outlined,
                  color: Colors.red.shade600,
                  onTap: openAddExpense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Add Income',
                  icon: Icons.savings_outlined,
                  color: Colors.green.shade600,
                  onTap: openAddIncome,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedTransactionIds.length} selected',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTransactionIds.clear();
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: _deleteSelectedTransactions,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
            ),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat,
                size: 36,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No recurring transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add recurring expenses such as rent, subscriptions, or monthly income.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}