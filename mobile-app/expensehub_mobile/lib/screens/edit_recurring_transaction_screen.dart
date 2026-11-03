import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../services/category_service.dart';
import '../services/recurring_transaction_service.dart';
import '../utils/error_messages.dart';


class EditRecurringTransactionScreen
    extends StatefulWidget {
  final RecurringTransaction transaction;

  const EditRecurringTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditRecurringTransactionScreen>
      createState() =>
          _EditRecurringTransactionScreenState();
}

class _EditRecurringTransactionScreenState
    extends State<EditRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final recurringService =
      RecurringTransactionService();
  final categoryService = CategoryService();

  late TextEditingController
      descriptionController;
  late TextEditingController
      amountController;

  late String selectedFrequency;
  late DateTime nextDueDate;

  String? selectedCategoryId;

  bool isLoading = false;
  late Future<List<Category>>
      categoriesFuture;

  bool get isIncome =>
      widget.transaction.type
          .toUpperCase() ==
      'INCOME';

  Color get mainColor => isIncome
      ? Colors.green.shade600
      : Colors.red.shade600;

  Color get lightColor => isIncome
      ? Colors.green.shade50
      : Colors.red.shade50;

  @override
  void initState() {
    super.initState();

    final transaction =
        widget.transaction;

    descriptionController =
        TextEditingController(
      text: transaction.description ??
          transaction.title,
    );

    amountController =
        TextEditingController(
      text: transaction.amount
          .toStringAsFixed(2),
    );

    selectedFrequency =
        transaction.frequency;
    nextDueDate =
        transaction.nextDueDate;
    selectedCategoryId =
        transaction.categoryId;

    categoriesFuture =
        categoryService.getCategories();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      nextDueDate = picked;
    });
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a category',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final updated =
          RecurringTransaction(
        id: widget.transaction.id,
        title: descriptionController.text
            .trim(),
        amount: double.parse(
          amountController.text.trim(),
        ),
        type: widget.transaction.type,
        category:
            widget.transaction.category,
        categoryId:
            selectedCategoryId,
        description:
            descriptionController.text
                .trim(),
        frequency: selectedFrequency,
        startDate:
            widget.transaction.startDate,
        nextDueDate: nextDueDate,
        active:
            widget.transaction.active,
        createdAt:
            widget.transaction.createdAt,
      );

      await recurringService
          .updateRecurringTransaction(
        updated,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Recurring transaction updated',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            getFriendlyError(error),
          ),
        ),
      );
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
      backgroundColor:
          Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              Navigator.pop(context),
          icon:
              const Icon(Icons.close),
        ),
        title: const Text(
          'Edit Recurring Transaction',
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.08),
                blurRadius: 18,
                offset:
                    const Offset(0, -6),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : saveChanges,
              style: FilledButton
                  .styleFrom(
                backgroundColor:
                    mainColor,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 18,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Text(
                      'Update Recurring Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            32,
          ),
          children: [
            const SizedBox(height: 14),
            Text(
              'Description',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
              ),
              child: TextFormField(
                controller:
                    descriptionController,
                maxLines: 2,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Recurring transaction name',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [
                          Colors.green
                              .shade500,
                          Colors.green
                              .shade800,
                        ]
                      : [
                          Colors.red.shade400,
                          Colors.red.shade800,
                        ],
                ),
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
              ),
              child: TextFormField(
                controller:
                    amountController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                textAlign:
                    TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .allow(
                    RegExp(
                      r'^\d*\.?\d{0,2}',
                    ),
                  ),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
                decoration:
                    const InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                  border:
                      InputBorder.none,
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Enter amount';
                  }

                  if (double.tryParse(
                          value) ==
                      null) {
                    return 'Enter a valid number';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Category>>(
              future: categoriesFuture,
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final categories =
                    (snapshot.data ?? [])
                        .where(
                  (category) {
                    final type = category
                            .type
                            ?.toUpperCase() ??
                        'EXPENSE';

                    return type ==
                        widget.transaction.type
                            .toUpperCase();
                  },
                ).toList();

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories
                      .map(
                    (category) {
                      final isSelected =
                          selectedCategoryId ==
                              category.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId =
                                category.id;
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration:
                              BoxDecoration(
                            color: isSelected
                                ? mainColor
                                : Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                            border:
                                Border.all(
                              color:
                                  mainColor,
                            ),
                          ),
                          child: Text(
                            category.name,
                            style:
                                TextStyle(
                              color: isSelected
                                  ? Colors
                                      .white
                                  : Colors
                                      .black87,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue:
                  selectedFrequency,
              decoration:
                  const InputDecoration(
                labelText: 'Repeat every',
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.all(
                    Radius.circular(18),
                  ),
                  borderSide: BorderSide
                      .none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'DAILY',
                  child: Text('Every day'),
                ),
                DropdownMenuItem(
                  value: 'WEEKLY',
                  child:
                      Text('Every week'),
                ),
                DropdownMenuItem(
                  value: 'MONTHLY',
                  child:
                      Text('Every month'),
                ),
                DropdownMenuItem(
                  value: 'YEARLY',
                  child:
                      Text('Every year'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedFrequency =
                      value;
                });
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: pickNextDueDate,
              child: Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(12),
                      decoration:
                          BoxDecoration(
                        color: lightColor,
                        shape: BoxShape
                            .circle,
                      ),
                      child: Icon(
                        Icons.event,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(
                        width: 16),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Next due date',
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          DateFormat(
                            'd MMM yyyy',
                          ).format(
                            nextDueDate,
                          ),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
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