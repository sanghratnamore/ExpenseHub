import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/error_messages.dart';
import '../models/category.dart';
import '../models/group.dart';
import '../services/category_service.dart';
import '../services/group_service.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class GroupAddExpenseScreen extends StatefulWidget {
  final Group group;

  const GroupAddExpenseScreen({super.key, required this.group});

  @override
  State<GroupAddExpenseScreen> createState() => _GroupAddExpenseScreenState();
}

class _GroupAddExpenseScreenState extends State<GroupAddExpenseScreen> {
  final GroupService _groupService = GroupService();
  final CategoryService _categoryService = CategoryService();

  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;

  bool _isLoadingCategories = true;
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  String? _paidById;
  final List<String> _selectedMemberIds = [];

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
          content: Text('Failed to load categories: ${error.toString()}'),
        ),
      );
    }
  }

  Future<void> _openAddCategorySheet() async {
    final nameController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add category',
                style: TextStyle(
                  color: kInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create a new category for your expenses.',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                cursorColor: kPrimary,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Category name',
                  hintStyle: const TextStyle(
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
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

                    Navigator.pop(context);

                    try {
                      final userId = await _categoryService.authService
                          .getUserId();

                      if (userId == null) {
                        throw Exception('Please log in again');
                      }

                      final newCategory = await _categoryService.createCategory(
                        name: name,
                        type: 'EXPENSE',
                        userId: userId,
                      );

                      if (!mounted) return;

                      await _loadCategories();

                      if (!mounted) return;

                      setState(() {
                        _selectedCategoryId = newCategory.id;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Category "$name" added')),
                      );
                    } catch (error) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Add category',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

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
      await _groupService.addGroupExpense(
        groupId: widget.group.id.toString(),
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
          'Add expense',
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

            const _SectionLabel(title: 'Expense details'),

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
                      children: [
                        ..._categories.map(buildCategoryChip),
                        GestureDetector(
                          onTap: _openAddCategorySheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: kPrimary.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 17,
                                  color: kPrimary,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Add category',
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
              onToggleMember: _toggleMember,
            ),

            const SizedBox(height: 28),

            FilledButton(
              onPressed: _isLoading ? null : _submitExpense,
              style: FilledButton.styleFrom(
                backgroundColor: kInk,
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
                      'Add group expense',
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
        boxShadow: [
          BoxShadow(
            color: kExpenseColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    letterSpacing: -1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;

      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  List<dynamic> get _filteredMembers {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return widget.members;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                onTap: _toggleSearch,
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
              focusNode: _searchFocusNode,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              cursorColor: kPrimary,
              style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Search members',
                hintStyle: const TextStyle(
                  color: kMuted,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: kMuted,
                ),
                filled: true,
                fillColor: kSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          if (_filteredMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No members found',
                style: TextStyle(color: kMuted, fontWeight: FontWeight.w700),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
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
                },
              ),
            ),
        ],
      ),
    );
  }
}