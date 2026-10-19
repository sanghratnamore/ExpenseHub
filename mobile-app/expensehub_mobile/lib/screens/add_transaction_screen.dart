import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Expense? expense;
  final String transactionType;

  const AddTransactionScreen({
    super.key,
    this.expense,
    required this.transactionType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final authService = AuthService();
  final categoryService = CategoryService();
  final expenseService = ExpenseService();

  late final TextEditingController amountController;
  late final TextEditingController descriptionController;

  String selectedType = 'EXPENSE';
  DateTime selectedDate = DateTime.now();
  int? selectedCategoryId;

  bool isLoading = false;
  late Future<List<Category>> categoriesFuture;

  Expense? get existingExpense => widget.expense;

  bool get isEditMode => existingExpense != null;

  bool get isIncome => selectedType == 'INCOME';

  Color get mainColor => isIncome ? Colors.green.shade600 : Colors.red.shade600;

  Color get lightColor => isIncome ? Colors.green.shade50 : Colors.red.shade50;

  @override
  void initState() {
    super.initState();

    amountController = TextEditingController(
      text: existingExpense?.amount.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: existingExpense?.description ?? '',
    );

    categoriesFuture = categoryService.getCategories();

    selectedType = widget.transactionType.toUpperCase();

    if (isEditMode) {
      selectedType = existingExpense!.type.toUpperCase();
      selectedDate = DateTime.parse(existingExpense!.date);
      selectedCategoryId = existingExpense!.categoryId;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isAfter(DateTime.now())
          ? DateTime.now()
          : selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final token = await authService.getToken();
    final userId = await authService.getUserId();

    if (!mounted) return;

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in again')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isEditMode) {
        await expenseService.updateExpense(
          id: existingExpense!.id,
          type: selectedType,
          amount: double.parse(amountController.text.trim()),
          description: descriptionController.text.trim(),
          date: selectedDate.toIso8601String().substring(0, 10),
          userId: int.parse(userId),
          categoryId: selectedCategoryId!,
        );
      } else {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8080/api/transactions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'type': selectedType,
            'amount': double.parse(amountController.text.trim()),
            'description': descriptionController.text.trim(),
            'date': selectedDate.toIso8601String().substring(0, 10),
            'userId': int.parse(userId),
            'categoryId': selectedCategoryId,
          }),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Failed: ${response.statusCode} ${response.body}');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: mainColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            isEditMode
                ? 'Transaction updated'
                : isIncome
                ? 'Income added'
                : 'Expense added',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          isEditMode
              ? 'Edit Transaction'
              : isIncome
              ? 'Add Income'
              : 'Add Expense',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const SizedBox(height: 14),

            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextFormField(
                controller: descriptionController,
                autofocus: !isEditMode,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: isIncome
                      ? 'e.g. Salary, Freelance work'
                      : 'e.g. Hotel, Grocery, Fuel',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    isIncome
                        ? Icons.savings_outlined
                        : Icons.shopping_bag_outlined,
                    color: mainColor,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 28),

            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isIncome
                      ? [Colors.green.shade500, Colors.green.shade800]
                      : [Colors.red.shade400, Colors.red.shade800],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter amount';
                  }

                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Category>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Category error: ${snapshot.error}');
                }

                final allCategories = snapshot.data ?? [];

                final categories = allCategories.where((category) {
                  final categoryType =
                      category.type?.toUpperCase() ?? 'EXPENSE';

                  return categoryType == selectedType;
                }).toList();

                if (categories.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'No $selectedType categories found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((category) {
                    final isSelected = selectedCategoryId == category.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryId = category.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? mainColor : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? mainColor
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: mainColor.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                key: ValueKey(isSelected),
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 28),

            const SizedBox(height: 14),

            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.calendar_month, color: mainColor),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction date',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d MMM yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: mainColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : saveTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isIncome ? Icons.savings : Icons.shopping_bag),
                          const SizedBox(width: 10),
                          Text(
                            isEditMode
                                ? 'Update Transaction'
                                : isIncome
                                ? 'Save Income'
                                : 'Save Expense',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
