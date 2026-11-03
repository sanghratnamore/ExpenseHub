import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import 'edit_recurring_transaction_screen.dart';

Future<void> showRecurringDetailsSheet({
  required BuildContext context,
  required RecurringTransaction transaction,
  required VoidCallback onChanged,
}) async {
  final recurringService = RecurringTransactionService();

  final isIncome = transaction.type.toUpperCase() == 'INCOME';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green.shade600, Colors.green.shade800]
                      : [Colors.red.shade500, Colors.red.shade800],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.savings : Icons.shopping_bag,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      transaction.active ? 'Active' : 'Paused',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    RecurringDetailCard(
                      icon: Icons.category,
                      title: 'Category',
                      value: transaction.category,
                    ),
                    const SizedBox(height: 12),
                    RecurringDetailCard(
                      icon: Icons.repeat,
                      title: 'Repeats',
                      value: getFrequencyText(transaction.frequency),
                    ),
                    const SizedBox(height: 12),
                    RecurringDetailCard(
                      icon: Icons.calendar_month,
                      title: 'Started on',
                      value: formatDate(transaction.startDate),
                    ),
                    const SizedBox(height: 12),
                    RecurringDetailCard(
                      icon: Icons.event,
                      title: 'Next due date',
                      value: transaction.active
                          ? formatDate(transaction.nextDueDate)
                          : 'Paused',
                    ),
                    if (transaction.description != null &&
                        transaction.description!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          RecurringDetailCard(
                            icon: Icons.notes,
                            title: 'Description',
                            value: transaction.description!,
                          ),
                        ],
                      ),
                    const SizedBox(height: 28),

                    // Primary action
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);

                          await toggleRecurring(
                            context: context,
                            transaction: transaction,
                            recurringService: recurringService,
                            onChanged: onChanged,
                          );
                        },
                        icon: Icon(
                          transaction.active
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 21,
                        ),
                        label: Text(
                          transaction.active
                              ? 'Pause recurring'
                              : 'Resume recurring',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: transaction.active
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Secondary actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(sheetContext);

                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditRecurringTransactionScreen(
                                          transaction: transaction,
                                        ),
                                  ),
                                );

                                if (updated == true) {
                                  onChanged();
                                }
                              },
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F766E),
                                side: BorderSide(
                                  color: const Color(0xFF0F766E)
                                      .withValues(alpha: 0.35),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);

                                deleteRecurring(
                                  context: context,
                                  transaction: transaction,
                                  recurringService: recurringService,
                                  onChanged: onChanged,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE11D48),
                                side: BorderSide(
                                  color: const Color(0xFFE11D48)
                                      .withValues(alpha: 0.35),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
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
      );
    },
  );
}

Future<void> toggleRecurring({
  required BuildContext context,
  required RecurringTransaction transaction,
  required RecurringTransactionService recurringService,
  required VoidCallback onChanged,
}) async {
  try {
    if (transaction.active) {
      await recurringService.pauseRecurringTransaction(transaction.id!);
    } else {
      await recurringService.resumeRecurringTransaction(transaction.id!);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          transaction.active
              ? 'Recurring transaction paused'
              : 'Recurring transaction resumed',
        ),
      ),
    );

    onChanged();
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Action failed: $error')));
  }
}

Future<void> deleteRecurring({
  required BuildContext context,
  required RecurringTransaction transaction,
  required RecurringTransactionService recurringService,
  required VoidCallback onChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete recurring transaction?'),
        content: Text(
          '${transaction.title} will no longer be created automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    await recurringService.deleteRecurringTransaction(transaction.id!);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recurring transaction deleted')),
    );

    onChanged();
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Delete failed: $error')));
  }
}

String getFrequencyText(String frequency) {
  switch (frequency.toUpperCase()) {
    case 'DAILY':
      return 'Every day';
    case 'WEEKLY':
      return 'Every week';
    case 'MONTHLY':
      return 'Every month';
    case 'YEARLY':
      return 'Every year';
    default:
      return 'Recurring';
  }
}

String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

class RecurringDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const RecurringDetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
