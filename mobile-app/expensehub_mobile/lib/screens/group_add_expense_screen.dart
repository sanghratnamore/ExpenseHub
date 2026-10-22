import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import '../models/group.dart';
import '../services/group_service.dart';

class GroupAddExpenseScreen extends StatefulWidget {
  final Group group;

  const GroupAddExpenseScreen({super.key, required this.group});

  @override
  State<GroupAddExpenseScreen> createState() => _GroupAddExpenseScreenState();
}

class _GroupAddExpenseScreenState extends State<GroupAddExpenseScreen> {
  final GroupService _groupService = GroupService();
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;

  DateTime _selectedDate = DateTime.now();
  int? _paidById;
  final List<int> _selectedMemberIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: ${error.toString()}'),
        ),
      );
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paidById == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select who paid')));
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one member')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.addGroupExpense(
        groupId: widget.group.id,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        expenseDate: _selectedDate.toIso8601String().substring(0, 10),
        paidBy: _paidById!,
        categoryId: _selectedCategoryId!,
        memberIds: _selectedMemberIds,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Hotel, Dinner, Taxi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Date: '
                  '${_selectedDate.toIso8601String().substring(0, 10)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),

              const SizedBox(height: 16),

              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Select category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Select a category';
                        }
                        return null;
                      },
                    ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _paidById,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                  border: OutlineInputBorder(),
                ),
                items: members
                    .map(
                      (member) => DropdownMenuItem<int>(
                        value: member.id,
                        child: Text(member.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _paidById = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              const Text('Split between'),

              ...members.map((member) {
                final isSelected = _selectedMemberIds.contains(member.id);

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(member.name),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedMemberIds.add(member.id);
                      } else {
                        _selectedMemberIds.remove(member.id);
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitExpense,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Group Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
