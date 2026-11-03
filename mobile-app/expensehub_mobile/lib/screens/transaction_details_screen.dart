import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import 'transaction_details_sheet.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends State<TransactionDetailsScreen> {
  final expenseService = ExpenseService();

  Expense? expense;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTransaction();
  }

  Future<void> loadTransaction() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await expenseService.getExpenseById(
        widget.transactionId,
      );

      if (!mounted) return;

      setState(() {
        expense = result;
        isLoading = false;
      });

      await openDetails();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> openDetails() async {
    final currentExpense = expense;

    if (currentExpense == null) return;

    await showTransactionDetailsSheet(
      context: context,
      expense: currentExpense,
      onChanged: () {
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Transaction Details'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!),
                )
              : const SizedBox.shrink(),
    );
  }
}