import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import 'add_recurring_transaction_screen.dart';


class RecurringTransactionsScreen
    extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});


  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}


class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final recurringService =
      RecurringTransactionService();


  List<RecurringTransaction> transactions = [];


  bool isLoading = true;


  String? errorMessage;


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


  Future<void> openAddScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AddRecurringTransactionScreen(),
      ),
    );


    if (result == true) {
      loadRecurringTransactions();
    }
  }


  Future<void> deleteTransaction(
      RecurringTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
              'Delete recurring transaction?'),
          content: Text(
            '${transaction.title} will no longer be created automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style:
                  FilledButton.styleFrom(
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
      await recurringService
          .deleteRecurringTransaction(
        transaction.id!,
      );


      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'Recurring transaction deleted'),
        ),
      );


      loadRecurringTransactions();
    } catch (error) {
      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
              'Delete failed: $error'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: openAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child:
                      Text(errorMessage!))
              : transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No recurring transactions yet',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          loadRecurringTransactions,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          16,
                          16,
                          100,
                        ),
                        itemCount:
                            transactions.length,
                        itemBuilder:
                            (context, index) {
                          final transaction =
                              transactions[
                                  index];


                          final isIncome =
                              transaction.type
                                      .toUpperCase() ==
                                  'INCOME';


                          final color = isIncome
                              ? Colors.green
                              : Colors.red;


                          return Container(
                            margin: const EdgeInsets
                                .only(
                              bottom: 12,
                            ),
                            padding:
                                const EdgeInsets
                                    .all(16),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 14,
                                  offset:
                                      const Offset(
                                    0,
                                    5,
                                  ),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment
                                      .center,
                                  decoration:
                                      BoxDecoration(
                                    color: color
                                        .withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape
                                        .circle,
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons
                                            .arrow_downward
                                        : Icons
                                            .arrow_upward,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(
                                    width: 14),
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
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 4),
                                      Text(
                                        '${transaction.frequency} • Next: ${DateFormat('dd MMM yyyy').format(transaction.nextDueDate)}',
                                        style:
                                            TextStyle(
                                          fontSize:
                                              12,
                                          color: Colors
                                              .grey
                                              .shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color: color,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      deleteTransaction(
                                    transaction,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons
                                        .delete_outline,
                                    color: Colors
                                        .red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}