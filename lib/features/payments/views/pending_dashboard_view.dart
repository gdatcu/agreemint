import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/payment_controller.dart';
import '../../contracts/controllers/contract_controller.dart';
import '../../contracts/views/unsigned_contracts_view.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/whatsapp_reminder_service.dart';
import '../../../core/services/email_service.dart';
import '../../../core/services/local_whatsapp_bot_service.dart';
import '../../../core/constants.dart';
import '../../../main.dart';
import '../../settings/controllers/business_settings_controller.dart';
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
  bool _isSendingEmail = false;

  void _sendWhatsAppNotification({
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp. Ensure it is installed and the phone number is valid.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmailNotification({
    required String recipientEmail,
    required Future<void> Function(EmailService service) action,
  }) async {
    final settings =
        ref.read(businessSettingsControllerProvider).asData?.value ??
            ref.read(businessSettingsControllerProvider).value;
    final dbKey = settings?.resendApiKey?.trim() ?? '';
    final envApiKey = ref.read(resendApiKeyProvider).trim();
    final effectiveKey = dbKey.isNotEmpty ? dbKey : envApiKey;

    if (effectiveKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Resend API key is not configured. Please set it in Business Settings or via --dart-define.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSendingEmail = true);
    try {
      final emailService = EmailService(apiKey: effectiveKey);
      await action(emailService);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

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
            if (_isSendingEmail) const LinearProgressIndicator(),
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
                            'Past due agreed payments. Click the WhatsApp or Email icon to send reminders.',
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
                  final dateStr = dueLocalDate.toString().split(' ')[0];
                  final amountDueNow = payment.amountDue - payment.amountPaid;

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
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Due: ${amountDueNow.toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Due Date: $dateStr',
                                style: TextStyle(
                                  color: isOverdue
                                      ? Colors.redAccent
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            tooltip: 'Remind via WhatsApp',
                            onPressed: () {
                              final contract = payment.enrollment?.contract;
                              final secureContractUrl = (contract?.id != null && contract!.id.isNotEmpty)
                                  ? '${AppConstants.clientPortalBaseUrl}${contract.id}'
                                  : (contract?.signedPdfUrl != null
                                      ? WhatsAppReminderService.buildDocGatewayUrl(
                                          rawPdfUrl: contract!.signedPdfUrl!,
                                          studentPhone: student?.phone,
                                          docTitle: 'Contract de Servicii Mentorat',
                                        )
                                      : null);

                              final secureInvoiceUrl = (payment.externalInvoiceUrl != null && payment.externalInvoiceUrl!.trim().isNotEmpty)
                                  ? WhatsAppReminderService.buildDocGatewayUrl(
                                      rawPdfUrl: payment.externalInvoiceUrl!,
                                      studentPhone: student?.phone,
                                      docTitle: 'Factură Fiscală SOLO ${payment.externalInvoiceNumber != null ? "#${payment.externalInvoiceNumber}" : ""}',
                                    )
                                  : null;

                              _sendWhatsAppNotification(
                                action: () => WhatsAppService.sendPaymentReminder(
                                  phone: student?.phone ?? '',
                                  name: student?.name ?? 'Cursant',
                                  amount: amountDueNow,
                                  dueDate: dateStr,
                                  currency: currency,
                                  contractUrl: secureContractUrl,
                                  invoiceUrl: secureInvoiceUrl,
                                  invoiceNumber: payment.externalInvoiceNumber,
                                  programName: program?.name,
                                  dueDateTime: payment.dueDate,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.email_outlined,
                                color: Colors.blue),
                            tooltip: 'Remind via Email',
                            onPressed: () {
                              if (student?.email == null ||
                                  student!.email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Student email is missing.')),
                                );
                                return;
                              }
                              final contract = payment.enrollment?.contract;
                              final secureContractUrl = (contract?.id != null && contract!.id.isNotEmpty)
                                  ? '${AppConstants.clientPortalBaseUrl}${contract.id}'
                                  : (contract?.signedPdfUrl != null
                                      ? WhatsAppReminderService.buildDocGatewayUrl(
                                          rawPdfUrl: contract!.signedPdfUrl!,
                                          studentPhone: student?.phone,
                                          docTitle: 'Contract de Servicii Mentorat',
                                        )
                                      : null);

                              final secureInvoiceUrl = (payment.externalInvoiceUrl != null && payment.externalInvoiceUrl!.trim().isNotEmpty)
                                  ? WhatsAppReminderService.buildDocGatewayUrl(
                                      rawPdfUrl: payment.externalInvoiceUrl!,
                                      studentPhone: student?.phone,
                                      docTitle: 'Factură Fiscală SOLO ${payment.externalInvoiceNumber != null ? "#${payment.externalInvoiceNumber}" : ""}',
                                    )
                                  : null;

                              _sendEmailNotification(
                                recipientEmail: student.email,
                                action: (service) =>
                                    service.sendPaymentReminder(
                                  email: student.email,
                                  name: student.name,
                                  amount: amountDueNow,
                                  dueDate: dateStr,
                                  currency: currency,
                                  contractUrl: secureContractUrl,
                                  invoiceUrl: secureInvoiceUrl,
                                  invoiceNumber: payment.externalInvoiceNumber,
                                  programName: program?.name,
                                  studentPhone: student?.phone,
                                  dueDateTime: payment.dueDate,
                                ),
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
