import 'package:flutter/material.dart';

import '../models/group.dart';
import '../models/group_balance.dart';
import '../models/group_expense.dart';
import '../services/group_service.dart';
import 'group_add_expense_screen.dart';
import '../models/settlement_suggestion.dart';
import '../models/settlement_record.dart';
import 'group_expense_detail_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final GroupService _groupService = GroupService();

  late Future<List<GroupExpense>> _expensesFuture;
  late Future<List<GroupBalance>> _balancesFuture;
  late Future<List<SettlementSuggestion>> _settlementsFuture;
  late Future<List<SettlementRecord>> _settlementHistoryFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
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

  Future<void> _recordSettlement(SettlementSuggestion suggestion) async {
    final amountController = TextEditingController(
      text: suggestion.amount.toStringAsFixed(2),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record Settlement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${suggestion.paidByName} pays '
              '${suggestion.paidToName}',
            ),
            const SizedBox(height: 8),
            Text(
              'Total suggested: '
              '₹${suggestion.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final enteredAmount = double.tryParse(amountController.text.trim());

    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    if (enteredAmount > suggestion.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot be more than '
            '₹${suggestion.amount.toStringAsFixed(2)}',
          ),
        ),
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
        amount: enteredAmount,
        settlementDate: DateTime.now().toIso8601String().substring(0, 10),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ₹${enteredAmount.toStringAsFixed(2)} settlement',
          ),
        ),
      );

      _refreshData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteExpense(GroupExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _groupService.deleteGroupExpense(
        groupId: widget.group.id,
        expenseId: expense.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Expense deleted')));

      _refreshData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Settle Up'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExpensesTab(),
            _buildBalancesTab(),
            _buildSettlementsTab(),
            _buildSettlementHistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => GroupAddExpenseScreen(group: widget.group),
              ),
            );

            if (result == true) {
              _refreshData();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return FutureBuilder<List<GroupExpense>>(
      future: _expensesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
          );
        }

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet'));
        }

        final totalSpent = expenses.fold<double>(
          0,
          (total, expense) => total + expense.amount,
        );

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Spent',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupExpenseDetailScreen(
                              group: widget.group,
                              expenseId: expense.id,
                            ),
                          ),
                        );

                        if (result == true) {
                          _refreshData();
                        }
                      },
                      leading: const Icon(Icons.receipt_long),
                      title: Text(expense.description),
                      subtitle: Text(
                        'Paid by ${expense.paidByName} • ${expense.expenseDate}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteExpense(expense),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalancesTab() {
    return FutureBuilder<List<GroupBalance>>(
      future: _balancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
          );
        }

        final balances = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final balance = balances[index];

            Color statusColor;

            if (balance.status == 'SHOULD_RECEIVE') {
              statusColor = Colors.green;
            } else if (balance.status == 'OWES') {
              statusColor = Colors.red;
            } else {
              statusColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    balance.userName.isNotEmpty
                        ? balance.userName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(balance.userName),
                subtitle: Text(
                  'Paid ₹${balance.totalPaid.toStringAsFixed(2)}\n'
                  'Share ₹${balance.totalShare.toStringAsFixed(2)}',
                ),
                trailing: Text(
                  balance.balance >= 0
                      ? '+₹${balance.balance.toStringAsFixed(2)}'
                      : '-₹${balance.balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettlementsTab() {
    return FutureBuilder<List<SettlementSuggestion>>(
      future: _settlementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
          );
        }

        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty) {
          return const Center(child: Text('Everyone is settled up'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        leading: const Icon(
                          Icons.swap_horiz,
                          color: Colors.blue,
                        ),
                        title: Text(
                          '${suggestion.paidByName} pays '
                          '${suggestion.paidToName}',
                        ),
                        subtitle: Text(suggestion.message),
                        trailing: Text(
                          '₹${suggestion.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _recordSettlement(suggestion),
                      child: const Text('Record'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettlementHistoryTab() {
    return FutureBuilder<List<SettlementRecord>>(
      future: _settlementHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
          );
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return const Center(child: Text('No settlements recorded yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final settlement = history[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.green),
                title: Text(
                  '${settlement.paidByName} paid '
                  '${settlement.paidToName}',
                ),
                subtitle: Text('Date: ${settlement.settlementDate}'),
                trailing: Text(
                  '₹${settlement.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
