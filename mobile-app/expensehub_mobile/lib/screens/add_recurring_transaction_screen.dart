import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';


class AddRecurringTransactionScreen
    extends StatefulWidget {
  const AddRecurringTransactionScreen(
      {super.key});


  @override
  State<AddRecurringTransactionScreen>
      createState() =>
          _AddRecurringTransactionScreenState();
}


class _AddRecurringTransactionScreenState
    extends State<
        AddRecurringTransactionScreen> {
  final formKey = GlobalKey<FormState>();


  final titleController =
      TextEditingController();


  final amountController =
      TextEditingController();


  final descriptionController =
      TextEditingController();


  final recurringService =
      RecurringTransactionService();


  String selectedType = 'EXPENSE';


  String selectedFrequency = 'MONTHLY';


  DateTime selectedDate = DateTime.now();


  bool isSaving = false;


  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }


  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(
        const Duration(days: 365 * 5),
      ),
    );


    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }


  Future<void> saveRecurringTransaction() async {
    if (!formKey.currentState!.validate()) {
      return;
    }


    final amount = double.tryParse(
      amountController.text.trim(),
    );


    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              'Enter a valid amount'),
        ),
      );
      return;
    }


    setState(() {
      isSaving = true;
    });


    try {
      final transaction =
          RecurringTransaction(
        title: titleController.text.trim(),
        amount: amount,
        type: selectedType,
        category: selectedType == 'INCOME'
            ? 'Income'
            : 'Other',
        description:
            descriptionController.text
                .trim(),
        frequency: selectedFrequency,
        startDate: selectedDate,
        nextDueDate: selectedDate,
      );


      await recurringService
          .createRecurringTransaction(
        transaction,
      );


      if (!mounted) return;


      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
              'Failed to save: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Add Recurring Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller:
                    titleController,
                decoration:
                    const InputDecoration(
                  labelText: 'Title',
                  hintText:
                      'Rent, Salary, Netflix',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Title is required';
                  }


                  return null;
                },
              ),


              const SizedBox(height: 16),


              TextFormField(
                controller:
                    amountController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Amount is required';
                  }


                  return null;
                },
              ),


              const SizedBox(height: 16),


              DropdownButtonFormField<
                  String>(
                initialValue: selectedType,
                decoration:
                    const InputDecoration(
                  labelText: 'Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'EXPENSE',
                    child:
                        Text('Expense'),
                  ),
                  DropdownMenuItem(
                    value: 'INCOME',
                    child: Text('Income'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedType =
                        value!;
                  });
                },
              ),


              const SizedBox(height: 16),


              DropdownButtonFormField<
                  String>(
                initialValue: selectedFrequency,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Repeat every',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'DAILY',
                    child: Text('Day'),
                  ),
                  DropdownMenuItem(
                    value: 'WEEKLY',
                    child: Text('Week'),
                  ),
                  DropdownMenuItem(
                    value: 'MONTHLY',
                    child: Text('Month'),
                  ),
                  DropdownMenuItem(
                    value: 'YEARLY',
                    child: Text('Year'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFrequency =
                        value!;
                  });
                },
              ),


              const SizedBox(height: 16),


              GestureDetector(
                onTap: pickDate,
                child: Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .all(16),
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .grey.shade100,
                    borderRadius:
                        BorderRadius
                            .circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_month,
                      ),
                      const SizedBox(
                          width: 10),
                      Text(
                        'Start date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                      ),
                    ],
                  ),
                ),
              ),


              const SizedBox(height: 16),


              TextFormField(
                controller:
                    descriptionController,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Description (optional)',
                ),
              ),


              const SizedBox(height: 28),


              SizedBox(
                width:
                    double.infinity,
                child: FilledButton(
                  onPressed: isSaving
                      ? null
                      : saveRecurringTransaction,
                  style: FilledButton
                      .styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 16,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Recurring',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}