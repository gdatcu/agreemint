import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/payment_controller.dart';
import '../../../core/services/whatsapp_reminder_service.dart';
import '../../../core/services/meta_whatsapp_service.dart';
import '../../../core/services/local_whatsapp_bot_service.dart';

class PendingDashboardView extends ConsumerWidget {
  const PendingDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPaymentsState =
        ref.watch(globalPendingPaymentsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Installments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'QualiAdept Bot Settings',
            onPressed: () => LocalWhatsAppBotService.openSettings(context),
          ),
        ],
      ),
      body: pendingPaymentsState.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All caught up!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No outstanding pending or partial payments.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final overduePayments = payments.where((p) {
            final due = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
            return due.isBefore(today);
          }).toList();

          return Column(
            children: [
              if (overduePayments.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${overduePayments.length} Overdue Payment${overduePayments.length > 1 ? 's' : ''} Requiring Action',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Past due agreed payments. Click the Meta Bot icon or WhatsApp icon to send reminders.',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final student = payment.enrollment?.student;
                    final program = payment.enrollment?.program;
                    final currency = program?.currency ?? 'RON';

                    // Calculate relative day differences
                    final dueLocalDate = DateTime(payment.dueDate.year,
                        payment.dueDate.month, payment.dueDate.day);
                    final todayLocalDate = DateTime(now.year, now.month, now.day);
                    final difference = dueLocalDate.difference(todayLocalDate).inDays;

                    final isOverdue = difference < 0;
                    final relativeDaysText = isOverdue
                        ? '${difference.abs()} days overdue'
                        : difference == 0
                            ? 'Due today'
                            : 'Due in $difference days';

                    final badgeColor = isOverdue
                        ? Colors.red
                        : difference == 0
                            ? Colors.orange
                            : Colors.blue;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isOverdue
                              ? Colors.red.withAlpha(128)
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: isOverdue ? 1.0 : 0.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  student?.name ?? 'Unknown Student',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                '${(payment.amountDue - payment.amountPaid).toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOverdue
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                program?.name ?? 'Unknown Program',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due: ${dueLocalDate.toString().split(' ')[0]}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      relativeDaysText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chat_outlined,
                                    color: Colors.green.shade600),
                                tooltip: 'Send WhatsApp Reminder',
                                onPressed: () {
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final dueDay = DateTime(dueLocalDate.year, dueLocalDate.month, dueLocalDate.day);
                                  final isDueTomorrow = dueDay.isAfter(today);

                                  WhatsAppReminderService.sendReminder(
                                    context: context,
                                    phone: student?.phone,
                                    studentName: student?.name ?? 'Cursant',
                                    programName: program?.name ?? 'Program Mentorat',
                                    amount: payment.amountDue - payment.amountPaid,
                                    currency: currency,
                                    dueDateStr: dueLocalDate.toString().split(' ')[0],
                                    isDueTomorrow: isDueTomorrow,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                    globalPendingPaymentsControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
