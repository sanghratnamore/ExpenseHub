import 'package:flutter/material.dart';

import '../models/expense.dart';
import 'add_transaction_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  final Expense? expense;
  final bool autoRecurring;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.autoRecurring = false,
  });

  @override
  Widget build(BuildContext context) {
    return AddTransactionScreen(
      expense: expense,
      transactionType: 'EXPENSE',
      autoRecurring: autoRecurring,
    );
  }
}