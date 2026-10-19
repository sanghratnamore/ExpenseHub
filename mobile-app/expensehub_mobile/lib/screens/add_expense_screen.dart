import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'add_transaction_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  Widget build(BuildContext context) {
    return AddTransactionScreen(
      expense: expense,
      transactionType: 'EXPENSE',
    );
  }
}