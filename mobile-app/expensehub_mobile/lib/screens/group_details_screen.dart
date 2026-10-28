import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/error_messages.dart';
import '../models/group.dart';
import '../models/group_balance.dart';
import '../models/group_expense.dart';
import '../models/settlement_record.dart';
import '../models/settlement_suggestion.dart';
import '../services/group_service.dart';
import 'group_add_expense_screen.dart';
import 'group_expense_detail_screen.dart';
import 'group_info_screen.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kIncomeColor = Color(0xFF059669);
const Color kExpenseColor = Color(0xFFE11D48);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  String? _currentUserId;
  late final TabController _tabController;

  late Future<List<GroupExpense>> _expensesFuture;
  late Future<List<GroupBalance>> _balancesFuture;
  late Future<List<SettlementSuggestion>> _settlementsFuture;
  late Future<List<SettlementRecord>> _settlementHistoryFuture;

  @override
  void initState() {
    super.initState();

    _loadCurrentUser();
    _tabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _expensesFuture = _groupService.getGroupExpenses(widget.group.id);

      _balancesFuture = _groupService.getGroupBalances(widget.group.id);

      _settlementsFuture = _groupService.getSettlementSuggestions(
        widget.group.id,
      );

      _settlementHistoryFuture = _groupService.getSettlementHistory(
        widget.group.id,
      );
    });
  }

  void _showPremiumSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kInk,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await _groupService.authService.getUserId();

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
      });
    } catch (_) {
      // Ignore for now
    }
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupAddExpenseScreen(group: widget.group),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _openGroupInfo() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GroupInfoScreen(group: widget.group)),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _recordSettlement(
    SettlementSuggestion suggestion, {
    required double amount,
    required bool addToPersonalFinance,
  }) async {
    if (amount <= 0) {
      _showPremiumSnackBar(
        message: 'Enter a valid amount',
        icon: Icons.error_outline_rounded,
        color: kExpenseColor,
      );
      return;
    }

    if (amount > suggestion.amount) {
      _showPremiumSnackBar(
        message:
            'Amount cannot be more than '
            '₹${suggestion.amount.toStringAsFixed(2)}',
        icon: Icons.error_outline_rounded,
        color: kExpenseColor,
      );
      return;
    }

    try {
      final payer = widget.group.members.firstWhere(
        (member) => member.name == suggestion.paidByName,
      );

      final receiver = widget.group.members.firstWhere(
        (member) => member.name == suggestion.paidToName,
      );

      await _groupService.recordSettlement(
        groupId: widget.group.id,
        paidBy: payer.id,
        paidTo: receiver.id,
        amount: amount,
        settlementDate: DateTime.now().toIso8601String().substring(0, 10),
        addToPersonalFinance: addToPersonalFinance,
      );

      if (!mounted) return;

      _showPremiumSnackBar(
        message:
            '₹${amount.toStringAsFixed(2)} '
            'settlement recorded',
        icon: Icons.check_circle_rounded,
        color: kIncomeColor,
      );

      _refreshData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
    }
  }

  Future<void> _deleteExpense(GroupExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: const Text(
          'Delete expense?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Delete “${expense.description}”? '
          'This cannot be undone.',
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

    try {
      await _groupService.deleteGroupExpense(
        groupId: widget.group.id,
        expenseId: expense.id,
      );

      if (!mounted) return;

      _showPremiumSnackBar(
        message: 'Expense deleted successfully',
        icon: Icons.delete_outline_rounded,
        color: kExpenseColor,
      );

      _refreshData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(getFriendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                widget.group.name.isNotEmpty
                    ? widget.group.name.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: GestureDetector(
                onTap: _openGroupInfo,
                child: Text(
                  widget.group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _openGroupInfo,
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_rounded, size: 16, color: kPrimary),
                  const SizedBox(width: 6),
                  Text(
                    widget.group.members.length.toString(),
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _GroupTabs(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesTab(),
                _buildSettlementsTab(),
                _buildBalancesTab(),
                _buildSettlementHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        backgroundColor: kInk,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Expense',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return FutureBuilder<List<GroupExpense>>(
      future: _expensesFuture,
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

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No expenses yet',
            message:
                'Add your first shared expense\n'
                'to start tracking balances.',
          );
        }

        final totalSpent = expenses.fold<double>(
          0,
          (total, expense) => total + expense.amount,
        );

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          color: kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              _ExpenseSummary(expenses: expenses, totalSpent: totalSpent),
              const SizedBox(height: 22),
              const Text(
                'All expenses',
                style: TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ...expenses.map(
                (expense) => _ExpenseTile(
                  expense: expense,
                  onTap: () async {
                    final refreshed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupExpenseDetailScreen(
                          group: widget.group,
                          expenseId: expense.id,
                        ),
                      ),
                    );

                    if (refreshed == true) {
                      _refreshData();
                    }
                  },
                  onDelete: () => _deleteExpense(expense),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalancesTab() {
    return FutureBuilder<List<GroupBalance>>(
      future: _balancesFuture,
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

        final balances = snapshot.data ?? [];

        if (balances.isEmpty) {
          return const _EmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: 'No balances yet',
            message:
                'Balances will appear once\n'
                'you add expenses.',
          );
        }

        final totalPaid = balances.fold<double>(
          0,
          (sum, balance) => sum + balance.totalPaid,
        );

        GroupBalance? myBalance;

        for (final balance in balances) {
          if (balance.userId == _currentUserId) {
            myBalance = balance;
            break;
          }
        }

        final myBalanceAmount = myBalance?.balance ?? 0;

        final myTotalToReceive = myBalanceAmount > 0 ? myBalanceAmount : 0.0;

        final myTotalOwed = myBalanceAmount < 0 ? myBalanceAmount.abs() : 0.0;

        final unsettledCount = balances
            .where((balance) => balance.balance != 0)
            .length;

        final sortedBalances = List<GroupBalance>.from(balances);

        sortedBalances.sort((a, b) => b.balance.compareTo(a.balance));

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          color: kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              _BalanceSummaryCard(
                totalPaid: totalPaid,
                myBalance: myBalanceAmount,
                myTotalToReceive: myTotalToReceive,
                myTotalOwed: myTotalOwed,
                unsettledCount: unsettledCount,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Member balances',
                    style: TextStyle(
                      color: kInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${balances.length} members',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...sortedBalances.map(
                (balance) => _BalanceTile(balance: balance),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettlementsTab() {
    return FutureBuilder<List<SettlementSuggestion>>(
      future: _settlementsFuture,
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

        final allSuggestions = snapshot.data ?? [];

        final suggestions = allSuggestions.where((suggestion) {
          return suggestion.paidById == _currentUserId ||
              suggestion.paidToId == _currentUserId;
        }).toList();

        if (suggestions.isEmpty) {
          return const _EmptyState(
            icon: Icons.verified_rounded,
            title: 'You are all settled',
            message:
                'No pending payments\n'
                'involving you.',
          );
        }

        final totalPending = suggestions.fold<double>(
          0,
          (sum, suggestion) => sum + suggestion.amount,
        );

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          color: kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              _SettlementSummaryCard(
                totalPending: totalPending,
                paymentCount: suggestions.length,
              ),
              const SizedBox(height: 24),
              const Text(
                'Suggested settlements',
                style: TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'These payments will clear all '
                'group balances.',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...suggestions.map(
                (suggestion) => _SettlementCard(
                  suggestion: suggestion,
                  currentUserId: _currentUserId ?? '',
                  onRecordWithAmount: (amount, addToPersonalFinance) =>
                      _recordSettlement(
                        suggestion,
                        amount: amount,
                        addToPersonalFinance: addToPersonalFinance,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettlementHistoryTab() {
    return FutureBuilder<List<SettlementRecord>>(
      future: _settlementHistoryFuture,
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

        final history = List<SettlementRecord>.from(snapshot.data ?? []);

        history.sort((a, b) {
          final aDate =
              DateTime.tryParse(a.settlementDate) ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final bDate =
              DateTime.tryParse(b.settlementDate) ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        if (history.isEmpty) {
          return const _EmptyState(
            icon: Icons.history_rounded,
            title: 'No settlements yet',
            message:
                'Recorded payments will\n'
                'appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          color: kPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              const Text(
                'Settlement history',
                style: TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ...history.map(
                (settlement) => _HistoryTile(settlement: settlement),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupTabs extends StatelessWidget {
  final TabController controller;

  const _GroupTabs({required this.controller});

  static const List<_TabData> _tabs = [
    _TabData(label: 'Expenses', icon: Icons.receipt_long_rounded),
    _TabData(label: 'Settle', icon: Icons.swap_horiz_rounded),
    _TabData(label: 'Balances', icon: Icons.account_balance_wallet_rounded),
    _TabData(label: 'History', icon: Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = controller.index == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.animateTo(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.symmetric(
                      horizontal: isSelected ? 4 : 3,
                      vertical: isSelected ? 2 : 5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 30, 41, 66)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  84,
                                  98,
                                  132,
                                ).withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            tab.icon,
                            key: ValueKey('$index-$isSelected'),
                            size: isSelected ? 18 : 17,
                            color: isSelected
                                ? const Color(0xFF5EEAD4)
                                : kMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: isSelected ? 11.5 : 11,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: isSelected ? Colors.white : kMuted,
                            letterSpacing: isSelected ? 0.1 : 0,
                          ),
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TabData {
  final String label;
  final IconData icon;

  const _TabData({required this.label, required this.icon});
}

class _ExpenseSummary extends StatelessWidget {
  final List<GroupExpense> expenses;
  final double totalSpent;

  const _ExpenseSummary({required this.expenses, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SPENT',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹${totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              '${expenses.length} '
              '${expenses.length == 1 ? 'expense' : 'expenses'}',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final GroupExpense expense;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  Color get _accent {
    final name = expense.description;

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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(Icons.receipt_long_rounded, color: _accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Paid by '
                    '${expense.paidByName} • '
                    '${expense.expenseDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '₹${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final GroupBalance balance;

  const _BalanceTile({required this.balance});

  Color get statusColor {
    if (balance.status == 'SHOULD_RECEIVE') {
      return kIncomeColor;
    }

    if (balance.status == 'OWES') {
      return kExpenseColor;
    }

    return kMuted;
  }

  String get statusLabel {
    if (balance.status == 'SHOULD_RECEIVE') {
      return 'Gets back';
    }

    if (balance.status == 'OWES') {
      return 'Owes';
    }

    return 'Settled';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              balance.userName.isNotEmpty
                  ? balance.userName.characters.first.toUpperCase()
                  : '?',
              style: TextStyle(
                color: statusColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid ₹${balance.totalPaid.toStringAsFixed(0)} '
                  '• Share ₹${balance.totalShare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.balance >= 0
                    ? '+₹${balance.balance.toStringAsFixed(0)}'
                    : '-₹${balance.balance.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor.withValues(alpha: 0.80),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final SettlementSuggestion suggestion;
  final String currentUserId;
  final void Function(double amount, bool addToPersonalFinance)
  onRecordWithAmount;

  const _SettlementCard({
    required this.suggestion,
    required this.currentUserId,
    required this.onRecordWithAmount,
  });

  bool get isCurrentUserPayer {
    return suggestion.paidById == currentUserId;
  }

  Future<void> _askPersonalFinanceChoice(
    BuildContext context,
    double amount,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: kPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Add to personal finance?',
                      style: TextStyle(
                        color: kInk,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimary.withValues(alpha: 0.10),
                      kPrimary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SETTLEMENT AMOUNT',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This will be recorded in the '
                      'group. You can also add it to '
                      'your personal expenses or income.',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onRecordWithAmount(amount, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Yes, add to personal finance',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onRecordWithAmount(amount, false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kInk,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCustomAmountSheet(BuildContext context) async {
    final amountController = TextEditingController(
      text: suggestion.amount.toStringAsFixed(2),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 22,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settle up',
                style: TextStyle(
                  color: kInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isCurrentUserPayer
                    ? 'You pay '
                          '${suggestion.paidToName}'
                    : '${suggestion.paidByName} '
                          'pays you',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                cursorColor: kPrimary,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: kPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                  hintText: 'Enter amount',
                  filled: true,
                  fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Suggested amount: '
                '₹${suggestion.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);

                    await _askPersonalFinanceChoice(context, amount);
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
                    'Record settlement',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
              _SettlementAvatar(
                name: suggestion.paidByName,
                color: kExpenseColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(width: 34, height: 2, color: kBorder),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: kMuted,
                    ),
                  ],
                ),
              ),
              _SettlementAvatar(
                name: suggestion.paidToName,
                color: kIncomeColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.paidByName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kExpenseColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Pays',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      suggestion.paidToName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: kIncomeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Receives',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, size: 18, color: kPrimary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Payment amount',
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '₹${suggestion.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                _openCustomAmountSheet(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                isCurrentUserPayer ? 'Settle up' : 'Mark received',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementAvatar extends StatelessWidget {
  final String name;
  final Color color;

  const _SettlementAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SettlementSummaryCard extends StatelessWidget {
  final double totalPending;
  final int paymentCount;

  const _SettlementSummaryCard({
    required this.totalPending,
    required this.paymentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withValues(alpha: 0.12),
            kPrimary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: kPrimary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pending settlements',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${totalPending.toStringAsFixed(0)}',
            style: const TextStyle(
              color: kPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$paymentCount payment'
            '${paymentCount == 1 ? '' : 's'} '
            'needed to settle this group',
            style: const TextStyle(
              color: kMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  final double totalPaid;
  final double myBalance;
  final double myTotalToReceive;
  final double myTotalOwed;
  final int unsettledCount;

  const _BalanceSummaryCard({
    required this.totalPaid,
    required this.myBalance,
    required this.myTotalToReceive,
    required this.myTotalOwed,
    required this.unsettledCount,
  });

  @override
  Widget build(BuildContext context) {
    final isSettled = myBalance == 0;
    final isOwed = myBalance > 0;

    final mainColor = isSettled
        ? kMuted
        : isOwed
        ? kIncomeColor
        : kExpenseColor;

    final mainLabel = isSettled
        ? 'You are settled'
        : isOwed
        ? 'You are owed'
        : 'You owe';

    final mainAmount = myBalance.abs();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mainColor.withValues(alpha: 0.12),
            mainColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: mainColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSettled
                      ? Icons.check_circle_rounded
                      : isOwed
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: mainColor,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your group balance',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mainLabel,
            style: TextStyle(
              color: kMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${mainAmount.toStringAsFixed(0)}',
            style: TextStyle(
              color: mainColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceSummaryItem(
                  label: 'Total spent',
                  value: '₹${totalPaid.toStringAsFixed(0)}',
                  color: kInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceSummaryItem(
                  label: 'You are owed',
                  value: '₹${myTotalToReceive.toStringAsFixed(0)}',
                  color: kIncomeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceSummaryItem(
                  label: 'You owe',
                  value: '₹${myTotalOwed.toStringAsFixed(0)}',
                  color: kExpenseColor,
                ),
              ),
            ],
          ),
          if (unsettledCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$unsettledCount member'
                '${unsettledCount == 1 ? '' : 's'} '
                'still have pending balances',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BalanceSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: kPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kMuted,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SettlementRecord settlement;

  const _HistoryTile({required this.settlement});

  Color get _accent {
    final colors = [
      kPrimary,
      const Color(0xFF0EA5E9),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    return colors[settlement.id.hashCode.abs() % colors.length];
  }

  String get _formattedDate {
    if (settlement.settledAt.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(settlement.settledAt);

    if (date == null) {
      return settlement.settledAt;
    }

    return DateFormat('d MMM yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${settlement.paidByName} '
                      'paid '
                      '${settlement.paidToName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${settlement.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: kIncomeColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (settlement.message.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                settlement.message,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
