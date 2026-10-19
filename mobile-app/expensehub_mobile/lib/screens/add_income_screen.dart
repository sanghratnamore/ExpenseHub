import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'add_transaction_screen.dart';

class AddIncomeScreen extends StatelessWidget {
  final Expense? expense;

  const AddIncomeScreen({super.key, this.expense});

  @override
  Widget build(BuildContext context) {
    return AddTransactionScreen(
      expense: expense,
      transactionType: 'INCOME',
    );
  }
}