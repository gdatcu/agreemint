import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/payment_controller.dart';
import '../../contracts/controllers/contract_controller.dart';
import '../../contracts/views/unsigned_contracts_view.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/whatsapp_reminder_service.dart';
import '../../../core/services/local_whatsapp_bot_service.dart';
import '../models/payment_model.dart';

class PendingDashboardView extends ConsumerStatefulWidget {
  const PendingDashboardView({super.key});

  @override
  ConsumerState<PendingDashboardView> createState() =>
      _PendingDashboardViewState();
}

class _PendingDashboardViewState extends ConsumerState<PendingDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingPaymentsState =
        ref.watch(globalPendingPaymentsControllerProvider);
    final contractsState = ref.watch(globalContractsControllerProvider);

    // Trigger daily unsigned contracts notification check safely
    contractsState.whenData((contracts) {
      NotificationService.checkAndNotifyUnsignedContracts(contracts);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'QualiAdept Bot Settings',
            onPressed: () => LocalWhatsAppBotService.openSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.payments_outlined),
              text: 'Unpaid Installments',
            ),
            Tab(
              icon: Icon(Icons.draw_outlined),
              text: 'Unsigned Contracts',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnpaidPaymentsTab(context, pendingPaymentsState),
          const UnsignedContractsView(),
        ],
      ),
    );
  }

  Widget _buildUnpaidPaymentsTab(
      BuildContext context, AsyncValue<List<PaymentModel>> pendingPaymentsState) {
    return pendingPaymentsState.when(
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
                            'Past due agreed payments. Click the WhatsApp icon to send reminders.',
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
                  final currency = program?.currency ?? 'EUR';
                  final dueLocalDate = payment.dueDate.toLocal();
                  final isOverdue = dueLocalDate.isBefore(today);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isOverdue
                            ? Colors.red.shade300
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: isOverdue ? 1.5 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            student?.name ?? 'Cursant Neidentificat',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOverdue ? 'Overdue' : 'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? Colors.red.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            program?.name ?? 'Program Mentorat',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Due: ${(payment.amountDue - payment.amountPaid).toStringAsFixed(2)} $currency',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Due Date: ${dueLocalDate.toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.grey.shade700,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
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
                              final dueDay = DateTime(dueLocalDate.year, dueLocalDate.month, dueLocalDate.day);
                              final daysUntilDue = dueDay.difference(today).inDays;

                              final contractPdf = payment.enrollment?.contract?.signedPdfUrl ?? payment.enrollment?.contract?.pdfUrl;

                              WhatsAppReminderService.sendReminder(
                                context: context,
                                phone: student?.phone,
                                studentName: student?.name ?? 'Cursant',
                                programName: program?.name ?? 'Program Mentorat',
                                amount: payment.amountDue - payment.amountPaid,
                                currency: currency,
                                dueDateStr: dueLocalDate.toString().split(' ')[0],
                                daysUntilDue: daysUntilDue,
                                invoiceUrl: payment.invoiceUrl,
                                invoiceNumber: payment.invoiceNumber,
                                contractPdfUrl: contractPdf,
                              );
                            },
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading pending payments: $err'),
      ),
    );
  }
}
