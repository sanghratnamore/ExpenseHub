import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class MonthlyDetailsScreen
    extends StatelessWidget {
  final int month;
  final List<Expense> expenses;

  const MonthlyDetailsScreen({
    super.key,
    required this.month,
    required this.expenses,
  });

  double getTotal(String type) {
    double total = 0;

    for (final expense in expenses) {
      if (expense.type.toUpperCase() == type) {
        total += expense.amount;
      }
    }

    return total;
  }

  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final income = getTotal('INCOME');
    final expense = getTotal('EXPENSE');
    final savings = income - expense;

    final sortedExpenses =
        List<Expense>.from(expenses)
          ..sort((a, b) {
            final dateA = DateTime.tryParse(
              a.createdAt ?? a.date,
            );

            final dateB = DateTime.tryParse(
              b.createdAt ?? b.date,
            );

            if (dateA == null ||
                dateB == null) {
              return 0;
            }

            return dateB.compareTo(dateA);
          });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('$monthName Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          32,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'Income',
                  amount: income,
                  color: Colors.green.shade600,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  title: 'Expense',
                  amount: expense,
                  color: Colors.red.shade600,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Savings',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${savings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'All transactions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (sortedExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                'No transactions in $monthName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ...sortedExpenses.map((expense) {
              final isIncome =
                  expense.type.toUpperCase() ==
                      'INCOME';

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            expense.description,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${expense.category} • ${DateFormat('d MMM').format(DateTime.parse(expense.date))}',
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'}₹${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: isIncome
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _DetailCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}