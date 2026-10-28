import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import '../models/group.dart';
import '../models/group_expense_detail.dart';
import '../services/group_service.dart';
import 'group_edit_expense_screen.dart';

import 'package:intl/intl.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class GroupExpenseDetailScreen extends StatefulWidget {
  final Group group;
  final String expenseId;

  const GroupExpenseDetailScreen({
    super.key,
    required this.group,
    required this.expenseId,
  });

  @override
  State<GroupExpenseDetailScreen> createState() =>
      _GroupExpenseDetailScreenState();
}

class _GroupExpenseDetailScreenState extends State<GroupExpenseDetailScreen> {
  final GroupService _groupService = GroupService();

  late Future<GroupExpenseDetail> _expenseDetailFuture;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadExpenseDetail();
  }

  void _loadExpenseDetail() {
    setState(() {
      _expenseDetailFuture = _groupService.getGroupExpenseDetail(
        groupId: widget.group.id,
        expenseId: widget.expenseId,
      );
    });
  }

  Future<void> _editExpense(GroupExpenseDetail expense) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupEditExpenseScreen(group: widget.group, expense: expense),
      ),
    );

    if (updated == true) {
      if (!mounted) return;

      _loadExpenseDetail();

      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(
          'Delete expense?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'This expense will be removed and group balances will be recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: kExpenseColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _groupService.deleteGroupExpense(
        groupId: widget.group.id,
        expenseId: widget.expenseId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Expense deleted')));

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Expense details',
          style: TextStyle(color: kInk, fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<GroupExpenseDetail>(
        future: _expenseDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
              ),
            );
          }

          final expense = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ExpenseHero(expense: expense),
              const SizedBox(height: 22),

              _PaidBySection(expense: expense),

              const SizedBox(height: 18),

              _InfoGrid(expense: expense),

              const SizedBox(height: 26),

              _SplitSection(expense: expense),

              const SizedBox(height: 28),

              _ActionButtons(
                isDeleting: _isDeleting,
                onEdit: () {
                  _editExpense(expense);
                },
                onDelete: _deleteExpense,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpenseHero extends StatelessWidget {
  final GroupExpenseDetail expense;

  const _ExpenseHero({required this.expense});

  DateTime? get _expenseDateTime => DateTime.tryParse(expense.expenseDate);

  String get _formattedDate {
    final dateTime = _expenseDateTime;

    if (dateTime == null) return expense.expenseDate;

    return DateFormat('d MMM yyyy').format(dateTime);
  }

  String get _formattedTime {
    final dateTime = _expenseDateTime;

    if (dateTime == null) return '--:--';

    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F2), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: kExpenseColor.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: kExpenseColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _formattedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: kExpenseColor.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.schedule_rounded,
                size: 12,
                color: kExpenseColor,
              ),
              const SizedBox(width: 5),
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            expense.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kInk,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kExpenseColor,
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(),
              Container(
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
                      Icons.category_rounded,
                      size: 13,
                      color: kExpenseColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      expense.categoryName ?? 'Other',
                      style: const TextStyle(
                        color: kInk,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaidBySection extends StatelessWidget {
  final GroupExpenseDetail expense;

  const _PaidBySection({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Paid by',
                style: TextStyle(
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
                  '1 payer',
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PayerTile(
            name: expense.paidByName,
            amount: expense.amount,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayerTile extends StatelessWidget {
  final String name;
  final double amount;
  final bool isPrimary;

  const _PayerTile({
    required this.name,
    required this.amount,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary
            ? Border.all(color: kPrimary.withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                color: kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPrimary ? 'Primary payer' : 'Co-payer',
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final GroupExpenseDetail expense;

  const _InfoGrid({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total amount',
            value: '₹${expense.amount.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.group_rounded,
            label: 'Split between',
            value: '${expense.splits.length} people',
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kExpenseColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 17, color: kExpenseColor),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: kMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kInk,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitSection extends StatelessWidget {
  final GroupExpenseDetail expense;

  const _SplitSection({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Split details',
                style: TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kExpenseColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${expense.splits.length}',
                  style: const TextStyle(
                    color: kExpenseColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (expense.splits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No split details available.',
                style: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
              ),
            )
          else
            ...expense.splits.map((split) => _SplitTile(split: split)),
        ],
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  final dynamic split;

  const _SplitTile({required this.split});

  Color get _accent {
    final name = split.userName ?? 'Member';

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
    final name = split.userName ?? 'Member';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
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
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(
                color: _accent,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member share',
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${split.shareAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionButtons({
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting ? null : onEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: kInk,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isDeleting ? null : onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: kExpenseColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              isDeleting ? 'Deleting' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
