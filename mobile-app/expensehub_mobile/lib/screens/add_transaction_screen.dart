import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils/error_messages.dart';
import '../services/recurring_transaction_service.dart';

import 'manage_categories_screen.dart';
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

  List<Expense> expenses = [];

  String selectedType = 'EXPENSE';
  DateTime selectedDate = DateTime.now();
  String? selectedCategoryId;

  bool isLoading = false;
  late Future<List<Category>> categoriesFuture;

  bool isRecurring = false;
  String selectedFrequency = 'MONTHLY';
  final recurringService = RecurringTransactionService();

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
    loadExpensesForUsage();

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

  Future<void> showRecurringInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lightColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.repeat, color: mainColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recurring Transaction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isIncome
                    ? 'This income will be added automatically again based on the repeat option you choose.'
                    : 'This expense will be added automatically again based on the repeat option you choose.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Example: If you select Every month, this transaction will repeat every month from the selected date.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> confirmRecurringSave() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.repeat, color: mainColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Save as recurring?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isIncome
                ? 'This income will be saved now and repeated automatically every ${selectedFrequency.toLowerCase()}.'
                : 'This expense will be saved now and repeated automatically every ${selectedFrequency.toLowerCase()}.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: mainColor),
              child: const Text('Save Recurring'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> loadExpensesForUsage() async {
    try {
      final result = await expenseService.getExpenses();

      if (!mounted) return;

      setState(() {
        expenses = result;
      });
    } catch (error) {
      // Category order will remain normal if
      // transactions cannot be loaded.
    }
  }

  List<Category> getSortedCategories(List<Category> categories) {
    final usageCount = <String, int>{};

    for (final expense in expenses) {
      if (expense.categoryId == null) continue;

      usageCount[expense.categoryId!] =
          (usageCount[expense.categoryId!] ?? 0) + 1;
    }

    final sorted = List<Category>.from(categories);

    sorted.sort((a, b) {
      final aCount = usageCount[a.id] ?? 0;
      final bCount = usageCount[b.id] ?? 0;

      return bCount.compareTo(aCount);
    });

    return sorted;
  }

  Color getCategoryColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.green,
      Colors.red,
    ];

    final index = name.hashCode.abs() % colors.length;

    return colors[index];
  }

  IconData getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('food') ||
        lowerName.contains('grocery') ||
        lowerName.contains('restaurant')) {
      return Icons.restaurant_outlined;
    } else if (lowerName.contains('travel') ||
        lowerName.contains('transport') ||
        lowerName.contains('fuel')) {
      return Icons.directions_car_outlined;
    } else if (lowerName.contains('shopping')) {
      return Icons.shopping_bag_outlined;
    } else if (lowerName.contains('bill') ||
        lowerName.contains('rent') ||
        lowerName.contains('electric')) {
      return Icons.receipt_long_outlined;
    } else if (lowerName.contains('health') || lowerName.contains('medical')) {
      return Icons.health_and_safety_outlined;
    } else if (lowerName.contains('salary') || lowerName.contains('income')) {
      return Icons.payments_outlined;
    } else if (lowerName.contains('gift')) {
      return Icons.card_giftcard_outlined;
    }

    return Icons.category_outlined;
  }

  Widget buildCategoryChip(Category category, {bool isMostUsed = false}) {
    final isSelected = selectedCategoryId == category.id;

    final categoryColor = getCategoryColor(category.name);

    final categoryIcon = getCategoryIcon(category.name);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryId = category.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    categoryColor,
                    categoryColor.withValues(alpha: 0.75),
                  ],
                )
              : null,
          color: isSelected ? null : categoryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? categoryColor
                : categoryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon,
              size: 17,
              color: isSelected ? Colors.white : categoryColor,
            ),
            const SizedBox(width: 7),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            if (isMostUsed && !isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.local_fire_department,
                size: 15,
                color: Colors.orange.shade600,
              ),
            ],
          ],
        ),
      ),
    );
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

  Future<void> openAddCategorySheet() async {
    final nameController = TextEditingController();

    final result = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isIncome
                    ? 'This will be added as an Income category'
                    : 'This will be added as an Expense category',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Category name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter category name')),
                      );
                      return;
                    }

                    final token = await authService.getToken();
                    final userId = await authService.getUserId();

                    if (!context.mounted) return;

                    if (token == null || userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in again')),
                      );
                      return;
                    }

                    try {
                      final newCategory = await categoryService.createCategory(
                        name: name,
                        type: selectedType,
                        userId: userId,
                      );

                      if (!context.mounted) return;

                      Navigator.pop(context, newCategory);
                    } catch (error) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Save Category'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      categoriesFuture = categoryService.getCategories();
      selectedCategoryId = result.id;
    });
  }

  Future<void> saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (!isEditMode && isRecurring) {
      final confirmed = await confirmRecurringSave();

      if (!confirmed) return;
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
          userId: userId,
          type: selectedType,
          amount: double.parse(amountController.text.trim()),
          description: descriptionController.text.trim(),
          date: selectedDate.toIso8601String().substring(0, 10),
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
            'userId': userId,
            'type': selectedType,
            'amount': double.parse(amountController.text.trim()),
            'description': descriptionController.text.trim(),
            'date': selectedDate.toIso8601String().substring(0, 10),
            'categoryId': selectedCategoryId,
            'isRecurring': isRecurring,
            'recurringFrequency': isRecurring ? selectedFrequency : null,
          }),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          debugPrint('Transaction save failed: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');

          throw Exception('Failed to save transaction: ${response.body}');
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
          .showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : saveTransaction,
              style: FilledButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
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

            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

            Row(
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ManageCategoriesScreen(categoryType: selectedType),
                      ),
                    );

                    if (changed == true) {
                      setState(() {
                        categoriesFuture = categoryService.getCategories();
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 17,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Category>>(
              future: categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
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

                final sortedCategories = getSortedCategories(categories);

                return Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isIncome ? Colors.green.shade50 : Colors.red.shade50,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isIncome
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: lightColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_fire_department_outlined,
                              size: 15,
                              color: mainColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Most used categories',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...sortedCategories.map((category) {
                                final isTopUsed =
                                    sortedCategories.indexOf(category) < 3;

                                return buildCategoryChip(
                                  category,
                                  isMostUsed: isTopUsed,
                                );
                              }),

                              GestureDetector(
                                onTap: openAddCategorySheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: mainColor.withValues(alpha: 0.45),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 17,
                                        color: mainColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'New',
                                        style: TextStyle(
                                          color: mainColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

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

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRecurring ? mainColor : Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 18, color: mainColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Recurring',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Switch(
                    value: isRecurring,
                    activeThumbColor: mainColor,
                    onChanged: (value) {
                      setState(() {
                        isRecurring = value;
                      });

                      if (value) {
                        showRecurringInfo();
                      }
                    },
                  ),
                ],
              ),
            ),
            if (isRecurring) ...[
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: selectedFrequency,
                decoration: InputDecoration(
                  labelText: 'Repeat every',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'DAILY', child: Text('Every day')),
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Every week')),
                  DropdownMenuItem(
                    value: 'MONTHLY',
                    child: Text('Every month'),
                  ),
                  DropdownMenuItem(value: 'YEARLY', child: Text('Every year')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFrequency = value!;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
