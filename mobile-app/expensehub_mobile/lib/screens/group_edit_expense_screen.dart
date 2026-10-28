import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/error_messages.dart';
import '../models/category.dart';
import '../models/group.dart';
import '../models/group_expense_detail.dart';
import '../services/category_service.dart';
import '../services/group_service.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kIncomeColor = Color(0xFF10B981);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class GroupEditExpenseScreen extends StatefulWidget {
  final Group group;
  final GroupExpenseDetail expense;

  const GroupEditExpenseScreen({
    super.key,
    required this.group,
    required this.expense,
  });

  @override
  State<GroupEditExpenseScreen> createState() => _GroupEditExpenseScreenState();
}

class _GroupEditExpenseScreenState extends State<GroupEditExpenseScreen> {
  final GroupService _groupService = GroupService();
  final CategoryService _categoryService = CategoryService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  List<Category> _categories = [];
  String? _selectedCategoryId;

  late DateTime _selectedDate;
  String? _paidById;
  final List<String> _selectedMemberIds = [];

  bool _isLoadingCategories = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    _descriptionController = TextEditingController(text: expense.description);

    _amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );

    _selectedDate = DateTime.tryParse(expense.expenseDate) ?? DateTime.now();

    _paidById = expense.paidById;

    _selectedCategoryId = expense.categoryId;

    for (final split in expense.splits) {
      _selectedMemberIds.add(split.userId);
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final allCategories = await _categoryService.getCategories();

      final expenseCategories = allCategories.where((category) {
        final type = category.type?.toUpperCase() ?? 'EXPENSE';
        return type == 'EXPENSE';
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = expenseCategories;
        _isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load categories: '
            '${error.toString()}',
          ),
        ),
      );
    }
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

  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  Color getCategoryColor(String name) {
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF0F766E),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFE11D48),
    ];

    return colors[name.hashCode.abs() % colors.length];
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
    }

    return Icons.category_outlined;
  }

  Widget buildCategoryChip(Category category) {
    final isSelected = _selectedCategoryId == category.id;

    final categoryColor = getCategoryColor(category.name);

    final categoryIcon = getCategoryIcon(category.name);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryId = category.id;
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
                color: isSelected ? Colors.white : kInk,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateExpense() async {
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

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.updateGroupExpense(
        groupId: widget.group.id,
        expenseId: widget.expense.id,
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
          .showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit expense',
          style: TextStyle(color: kInk, fontWeight: FontWeight.w900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _AmountHero(
              controller: _amountController,
              selectedDate: _selectedDate,
              onPickDate: _pickDate,
            ),

            const SizedBox(height: 22),

            _SectionLabel(title: 'Expense details'),

            const SizedBox(height: 14),

            _LabeledField(
              label: 'Description',
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                ),
                decoration: _inputDecoration(hint: 'Hotel, Dinner, Taxi'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter description';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),

            _isLoadingCategories
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(color: kPrimary),
                    ),
                  )
                : _LabeledField(
                    label: 'Category',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories
                          .map((category) => buildCategoryChip(category))
                          .toList(),
                    ),
                  ),

            const SizedBox(height: 16),

            _MemberPickerSection(
              title: 'Paid by',
              countLabel: '1 payer',
              members: members,
              selectedMemberId: _paidById,
              selectedMemberIds: const [],
              isMultiSelect: false,
              onToggleMember: (memberId) {
                setState(() {
                  _paidById = memberId;
                });
              },
            ),

            const SizedBox(height: 16),

            _MemberPickerSection(
              title: 'Split between',
              countLabel: '${_selectedMemberIds.length} selected',
              members: members,
              selectedMemberId: null,
              selectedMemberIds: _selectedMemberIds,
              isMultiSelect: true,
              onToggleMember: (memberId) {
                _toggleMember(memberId);
              },
            ),

            const SizedBox(height: 28),

            FilledButton(
              onPressed: _isLoading ? null : _updateExpense,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save changes',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _AmountHero extends StatelessWidget {
  final TextEditingController controller;
  final DateTime selectedDate;
  final VoidCallback onPickDate;

  const _AmountHero({
    required this.controller,
    required this.selectedDate,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F2), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Amount',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onPickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: kExpenseColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMM yyyy').format(selectedDate),
                        style: const TextStyle(
                          color: kInk,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  color: kExpenseColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: kInk,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MemberSelectTile extends StatelessWidget {
  final dynamic member;
  final bool isSelected;
  final VoidCallback onToggle;

  const _MemberSelectTile({
    required this.member,
    required this.isSelected,
    required this.onToggle,
  });

  Color get _accent {
    final name = member.name as String;

    final colors = [
      kPrimary,
      const Color(0xFF0EA5E9),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _accent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                member.name.isNotEmpty
                    ? member.name.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSelected ? _accent : kBorder,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPickerSection extends StatefulWidget {
  final String title;
  final String countLabel;
  final List<dynamic> members;
  final String? selectedMemberId;
  final List<String> selectedMemberIds;
  final bool isMultiSelect;
  final ValueChanged<String> onToggleMember;

  const _MemberPickerSection({
    required this.title,
    required this.countLabel,
    required this.members,
    required this.selectedMemberId,
    required this.selectedMemberIds,
    required this.isMultiSelect,
    required this.onToggleMember,
  });

  @override
  State<_MemberPickerSection> createState() => _MemberPickerSectionState();
}

class _MemberPickerSectionState extends State<_MemberPickerSection> {
  bool _isSearching = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredMembers {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.members;
    }

    return widget.members.where((member) {
      return member.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.countLabel,
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = !_isSearching;

                    if (!_isSearching) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    size: 16,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (_isSearching) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search members',
                filled: true,
                fillColor: kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          ..._filteredMembers.map((member) {
            final memberId = member.id.toString();

            final isSelected = widget.isMultiSelect
                ? widget.selectedMemberIds.contains(memberId)
                : widget.selectedMemberId == memberId;

            return _MemberSelectTile(
              member: member,
              isSelected: isSelected,
              onToggle: () {
                widget.onToggleMember(memberId);
              },
            );
          }),
        ],
      ),
    );
  }
}
