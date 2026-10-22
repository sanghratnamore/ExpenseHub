import 'package:flutter/material.dart';


import '../models/group.dart';
import '../models/group_expense_detail.dart';
import '../services/group_service.dart';


class GroupExpenseDetailScreen extends StatefulWidget {
  final Group group;
  final int expenseId;


  const GroupExpenseDetailScreen({
    super.key,
    required this.group,
    required this.expenseId,
  });


  @override
  State<GroupExpenseDetailScreen> createState() =>
      _GroupExpenseDetailScreenState();
}


class _GroupExpenseDetailScreenState
    extends State<GroupExpenseDetailScreen> {
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
      _expenseDetailFuture =
          _groupService.getGroupExpenseDetail(
        groupId: widget.group.id,
        expenseId: widget.expenseId,
      );
    });
  }


  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Delete this expense?\n\n'
          'Balances and Settle Up will be recalculated.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );


    if (confirmed != true) {
      return;
    }


    setState(() {
      _isDeleting = true;
    });


    try {
      await _groupService.deleteGroupExpense(
        groupId: widget.group.id,
        expenseId: widget.expenseId,
      );


      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
        ),
      );


      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
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
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: FutureBuilder<GroupExpenseDetail>(
        future: _expenseDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }


          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }


          final expense = snapshot.data!;


          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${expense.amount
                                  .toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expense.expenseDate,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Paid by '
                              '${expense.paidByName}',
                            ),
                          ],
                        ),
                        if (expense.categoryName != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.category,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  expense.categoryName!,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 16),


                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Split Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (expense
                              .splits.isEmpty)
                            const Text(
                              'No split details available.',
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: expense
                                    .splits.length,
                                itemBuilder:
                                    (context, index) {
                                  final split = expense
                                          .splits[
                                      index];


                                  return ListTile(
                                    contentPadding:
                                        EdgeInsets.zero,
                                    leading:
                                        const CircleAvatar(
                                      child: Icon(
                                        Icons.person,
                                      ),
                                    ),
                                    title: Text(
                                      split.userName ??
                                          'Member',
                                    ),
                                    trailing: Text(
                                      '₹${split.shareAmount
                                              .toStringAsFixed(
                                        2,
                                      )}',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 16),


                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    onPressed: _isDeleting
                        ? null
                        : _deleteExpense,
                    icon: _isDeleting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                          ),
                    label: Text(
                      _isDeleting
                          ? 'Deleting...'
                          : 'Delete Expense',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}