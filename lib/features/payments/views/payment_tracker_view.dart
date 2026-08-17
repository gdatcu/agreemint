import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../students/models/enrollment_model.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
import '../../../core/services/frankfurter_service.dart';
import '../../../core/services/whatsapp_reminder_service.dart';
import '../services/receipt_generator_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/invoice_storage_service.dart';
import 'receipt_preview_dialog.dart';

class PaymentTrackerView extends ConsumerStatefulWidget {
  final EnrollmentModel enrollment;

  const PaymentTrackerView({super.key, required this.enrollment});

  @override
  ConsumerState<PaymentTrackerView> createState() => _PaymentTrackerViewState();
}

class _PaymentTrackerViewState extends ConsumerState<PaymentTrackerView> {
  double? _liveRate;

  @override
  void initState() {
    super.initState();
    _fetchLiveRate();
  }

  void _fetchLiveRate() async {
    final program = widget.enrollment.program;
    if (program != null && program.currency == 'EUR') {
      final rate = await FrankfurterService.getEurToRonRate();
      if (mounted) {
        setState(() {
          _liveRate = rate;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Refunded':
        return Colors.amber.shade800;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.red;
    }
  }

  String _formatAmount(double amount, String currency) {
    if (currency == 'EUR') {
      final eurText = '${amount.toStringAsFixed(2)} EUR';
      if (_liveRate != null) {
        final ronVal = amount * _liveRate!;
        return '$eurText (~${ronVal.toStringAsFixed(2)} RON)';
      }
      return eurText;
    }
    return '${amount.toStringAsFixed(2)} $currency';
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = widget.enrollment;
    final program = enrollment.program;
    final currency = program?.currency ?? 'RON';
    final paymentsState =
        ref.watch(enrollmentPaymentsControllerProvider(enrollment.id));
    final student = enrollment.student;

    // Listen for state changes to display SnackBars for errors
    ref.listen(enrollmentPaymentsControllerProvider(enrollment.id),
        (previous, next) {
      if (next is AsyncError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title:
            Text(student != null ? '${student.name} - Payments' : 'Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Add Installment',
            onPressed: () => _showAddInstallmentDialog(context, ref),
          ),
        ],
      ),
      body: paymentsState.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Payment Schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a payment schedule or add custom installments for the mentorship fee.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showGeneratePlanDialog(context, ref),
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Generate Plan'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showAddInstallmentDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Single Installment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate summary stats
          final isContractRefunded = enrollment.contract?.status == 'Refunded' ||
              enrollment.contract?.status == 'Cancelled';

          final totalDue =
              payments.fold<double>(0, (sum, p) => sum + p.amountDue);
          final totalPaid = isContractRefunded
              ? 0.0
              : payments.fold<double>(0, (sum, p) => p.status == 'Refunded' ? sum : sum + p.amountPaid);
          final remaining = isContractRefunded
              ? 0.0
              : ((totalDue - totalPaid) > 0 ? (totalDue - totalPaid) : 0.0);

          return Column(
            children: [
              // Refunded Contract Alert Banner
              if (isContractRefunded) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.replay_rounded, color: Colors.amber.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Contract Refunded & Cancelled. Total Paid is set to 0.00 $currency.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (payments.any((p) => p.status != 'Refunded')) ...[
                          TextButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(paymentRepositoryProvider)
                                  .markPaymentsAsRefunded(enrollment.id);
                              ref.invalidate(
                                  enrollmentPaymentsControllerProvider(enrollment.id));
                            },
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text('Sync Refund'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // EUR Exchange Rate Info Banner
              if (currency == 'EUR') ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_exchange,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _liveRate != null
                                ? 'Frankfurter API Live Rate: 1 EUR = ${_liveRate!.toStringAsFixed(4)} RON'
                                : 'Fetching live EUR → RON exchange rate from Frankfurter API...',
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Summary Banner Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total Plan Price',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalDue, currency),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 30,
                            width: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                                .withAlpha(51)),
                        Column(
                          children: [
                            const Text('Total Paid',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(totalPaid, currency),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isContractRefunded
                                    ? Colors.amber.shade800
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            height: 30,
                            width: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                                .withAlpha(51)),
                        Column(
                          children: [
                            const Text('Remaining',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(remaining, currency),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: remaining > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Schedule (${payments.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddInstallmentDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Installment'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final dateStr =
                        payment.dueDate.toLocal().toString().split(' ')[0];

                    // Determine effective display status and paid amount
                    final isRefundedItem = isContractRefunded || payment.status == 'Refunded';
                    final isFullyPaid = !isRefundedItem &&
                        payment.amountPaid >= payment.amountDue &&
                        payment.amountDue > 0;

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final dueLocalDate = DateTime(payment.dueDate.year, payment.dueDate.month, payment.dueDate.day);
                    final isOverdue = !isRefundedItem &&
                        !isFullyPaid &&
                        dueLocalDate.isBefore(today);

                    final displayStatus = isRefundedItem
                        ? 'Refunded'
                        : (isFullyPaid
                            ? 'Paid'
                            : (isOverdue ? 'Overdue' : (payment.status.isNotEmpty ? payment.status : 'Pending')));
                    final effectivePaid = isRefundedItem ? 0.0 : payment.amountPaid;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Installment #${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(displayStatus)
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(displayStatus),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Due: ${_formatAmount(payment.amountDue, currency)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'Paid: ${_formatAmount(effectivePaid, currency)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isRefundedItem
                                        ? Colors.amber.shade800
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Due Date: $dateStr',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                ),
                                if (payment.isReceiptSigned) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified,
                                            size: 11,
                                            color: Colors.green.shade700),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Receipt Signed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (payment.externalInvoiceNumber != null &&
                                    payment.externalInvoiceNumber!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showSoloInvoiceDialog(
                                        context, ref, payment),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.blue.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.description,
                                              size: 11,
                                              color: Colors.blue.shade700),
                                          const SizedBox(width: 3),
                                          Text(
                                            'SOLO #${payment.externalInvoiceNumber}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _showSoloInvoiceDialog(
                                        context, ref, payment),
                                    child: Tooltip(
                                      message:
                                          'No SOLO invoice uploaded yet (will appear once generated in SOLO)',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.orange.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: 11,
                                              color: Colors.orange.shade800,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'No SOLO Invoice',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (payment.paymentMethod != null &&
                                payment.paymentMethod!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Method: ${payment.paymentMethod}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.post_add,
                                size: 20,
                                color: payment.externalInvoiceNumber != null
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                              ),
                              tooltip: 'SOLO / External Invoice',
                              onPressed: () => _showSoloInvoiceDialog(
                                  context, ref, payment),
                            ),
                            if (payment.amountPaid > 0)
                              IconButton(
                                icon: Icon(
                                  Icons.receipt_long,
                                  size: 20,
                                  color: payment.isReceiptSigned
                                      ? Colors.green.shade700
                                      : Colors.indigo,
                                ),
                                tooltip: payment.isReceiptSigned
                                    ? 'View Signed Receipt'
                                    : 'Chitanță / Generate Receipt PDF',
                                onPressed: () => _generateAndShowReceipt(
                                    context, payment, index + 1, payments.length),
                              ),
                            if (displayStatus != 'Paid' &&
                                displayStatus != 'Refunded' &&
                                !isContractRefunded) ...[
                              IconButton(
                                icon: Icon(Icons.chat_outlined,
                                    size: 20, color: Colors.green.shade600),
                                tooltip: 'Send WhatsApp Reminder',
                                onPressed: () {
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final dueDay = DateTime(payment.dueDate.year, payment.dueDate.month, payment.dueDate.day);
                                  final daysUntilDue = dueDay.difference(today).inDays;

                                  final contractPdf = widget.enrollment.contract?.signedPdfUrl ?? widget.enrollment.contract?.pdfUrl;

                                  WhatsAppReminderService.sendReminder(
                                    context: context,
                                    phone: student?.phone,
                                    studentName: student?.name ?? 'Cursant',
                                    programName: program?.name ?? 'Program Mentorat',
                                    amount: payment.amountDue - payment.amountPaid,
                                    currency: currency,
                                    dueDateStr: dateStr,
                                    daysUntilDue: daysUntilDue,
                                    invoiceUrl: payment.invoiceUrl,
                                    invoiceNumber: payment.invoiceNumber,
                                    contractPdfUrl: contractPdf,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit / Record Payment',
                                onPressed: () =>
                                    _showRecordPaymentDialog(context, ref, payment),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                tooltip: 'Delete Installment',
                                onPressed: () =>
                                    _showDeleteInstallmentDialog(context, ref, payment),
                              ),
                            ] else ...[
                              IconButton(
                                icon: Icon(Icons.lock_outline,
                                    size: 20, color: Colors.grey.shade400),
                                tooltip: displayStatus == 'Refunded' || isContractRefunded
                                    ? 'Contract / Payment Refunded: Cannot be edited or deleted'
                                    : 'Payment settled: Paid installments cannot be edited or deleted',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(displayStatus == 'Refunded' || isContractRefunded
                                          ? 'Refunded installments cannot be modified or deleted.'
                                          : 'Paid installments cannot be modified or deleted.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          if (displayStatus == 'Paid' ||
                              displayStatus == 'Refunded' ||
                              isContractRefunded) {
                            if (payment.amountPaid > 0) {
                              _generateAndShowReceipt(
                                  context, payment, index + 1, payments.length);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(displayStatus == 'Refunded' || isContractRefunded
                                      ? 'Refunded installments cannot be modified.'
                                      : 'Paid installments cannot be modified.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } else {
                            _showRecordPaymentDialog(context, ref, payment);
                          }
                        },
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
                    enrollmentPaymentsControllerProvider(widget.enrollment.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGeneratePlanDialog(BuildContext context, WidgetRef ref) {
    final program = widget.enrollment.program;
    final programPrice = program != null ? program.totalPrice : 0.0;
    final currency = program?.currency ?? 'RON';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Payment Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mentorship Price: ${_formatAmount(programPrice, currency)}'),
              const SizedBox(height: 16),
              const Text('Select number of installments:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ...[1, 2, 3, 6].map((installments) {
              final label = installments == 1
                  ? 'Full Pay'
                  : '$installments Installments';
              return TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref
                      .read(enrollmentPaymentsControllerProvider(widget.enrollment.id)
                          .notifier)
                      .generatePlan(
                        totalAmount: programPrice,
                        numberOfInstallments: installments,
                      );
                  navigator.pop();
                },
                child: Text(label),
              );
            }),
          ],
        );
      },
    );
  }

  void _showAddInstallmentDialog(BuildContext context, WidgetRef ref) {
    final isContractRefunded = widget.enrollment.contract?.status == 'Refunded' ||
        widget.enrollment.contract?.status == 'Cancelled';
    if (isContractRefunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add installments to a refunded or cancelled contract.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currency = widget.enrollment.program?.currency ?? 'RON';
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    String selectedMethod = 'Cash';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Custom Installment'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount Due ($currency)',
                        hintText: 'e.g., 250.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter amount due';
                        }
                        final amount = double.tryParse(val.trim());
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration:
                          const InputDecoration(labelText: 'Payment Method'),
                      items: ['Cash', 'Bank Transfer', 'Card'].map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                          selectedDate.toIso8601String().split('T')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final navigator = Navigator.of(context);
                      final amountDue =
                          double.parse(amountController.text.trim());

                      await ref
                          .read(enrollmentPaymentsControllerProvider(
                                  widget.enrollment.id)
                              .notifier)
                          .addExtraInstallment(
                            amountDue: amountDue,
                            dueDate: selectedDate,
                            paymentMethod: selectedMethod,
                          );

                      navigator.pop();
                    }
                  },
                  child: const Text('Add Installment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSoloInvoiceDialog(
      BuildContext context, WidgetRef ref, PaymentModel payment) {
    final invoiceNumberController =
        TextEditingController(text: payment.externalInvoiceNumber ?? '');
    final invoiceUrlController =
        TextEditingController(text: payment.externalInvoiceUrl ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.description_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('SOLO External Invoice'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record invoice number and PDF link generated in SOLO or external billing software.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: invoiceNumberController,
                  decoration: const InputDecoration(
                    labelText: 'SOLO Invoice Number (e.g. SOLO-10492)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: invoiceUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice PDF Link / Storage URL (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file, color: Colors.blue),
                  label: const Text('📁 Select & Upload SOLO PDF Invoice'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        if (file.bytes != null) {
                          final number = invoiceNumberController.text.trim();
                          final invNum =
                              number.isNotEmpty ? number : 'SOLO-PDF';

                          final uploadedUrl = await ref
                              .read(enrollmentPaymentsControllerProvider(
                                      widget.enrollment.id)
                                  .notifier)
                              .uploadSoloInvoicePdf(
                                paymentId: payment.id,
                                invoiceNumber: invNum,
                                pdfBytes: file.bytes!,
                                fileName: file.name,
                              );

                          invoiceUrlController.text = uploadedUrl;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'SOLO PDF uploaded and attached successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Upload failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final number = invoiceNumberController.text.trim();
                final url = invoiceUrlController.text.trim();
                if (number.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an invoice number')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                await ref
                    .read(enrollmentPaymentsControllerProvider(
                            widget.enrollment.id)
                        .notifier)
                    .saveExternalInvoice(
                      paymentId: payment.id,
                      invoiceNumber: number,
                      invoiceUrl: url.isNotEmpty ? url : null,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('SOLO Invoice $number saved.')),
                  );
                }
              },
              child: const Text('Save Invoice'),
            ),
          ],
        );
      },
    );
  }

  void _showRecordPaymentDialog(
      BuildContext context, WidgetRef ref, PaymentModel payment) {
    final isContractRefunded = widget.enrollment.contract?.status == 'Refunded' ||
        widget.enrollment.contract?.status == 'Cancelled';
    if (payment.status == 'Paid' ||
        payment.status == 'Refunded' ||
        isContractRefunded ||
        (payment.amountPaid >= payment.amountDue && payment.amountDue > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment.status == 'Refunded' || isContractRefunded
              ? 'Refunded installments cannot be modified.'
              : 'Paid installments cannot be modified after settlement.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currency = widget.enrollment.program?.currency ?? 'RON';
    final formKey = GlobalKey<FormState>();

    final amountDueController =
        TextEditingController(text: payment.amountDue.toStringAsFixed(2));
    final amountPaidController =
        TextEditingController(text: payment.amountPaid.toStringAsFixed(2));
    String selectedMethod = payment.paymentMethod ?? 'Cash';

    // Auto-calculate initial status
    String selectedStatus = (payment.amountPaid >= payment.amountDue && payment.amountDue > 0)
        ? 'Paid'
        : (payment.status.isNotEmpty ? payment.status : 'Pending');

    bool createFollowUp = false;

    DateTime selectedDueDate = payment.dueDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(payment.status == 'Paid' ? 'Edit Payment Record' : 'Record / Edit Payment'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final due = double.tryParse(amountDueController.text.trim()) ?? payment.amountDue;
              final paid = double.tryParse(amountPaidController.text.trim()) ?? payment.amountPaid;
              final remainingForThis = (due - paid) > 0 ? (due - paid) : 0.0;
              final isFullCoverage = paid >= due && due > 0;

              if (isFullCoverage && selectedStatus != 'Paid') {
                selectedStatus = 'Paid';
              }

              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: amountDueController,
                        decoration: InputDecoration(
                          labelText: 'Amount Due ($currency)',
                          hintText: 'e.g., 50.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount due';
                          final d = double.tryParse(val.trim());
                          if (d == null || d <= 0) return 'Enter valid positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountPaidController,
                        decoration: InputDecoration(
                          labelText: 'Amount Paid ($currency)',
                          hintText: 'e.g., 50.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount paid';
                          final p = double.tryParse(val.trim());
                          if (p == null || p < 0) return 'Enter valid non-negative number';
                          if (p > due) return 'Amount paid cannot exceed amount due';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${selectedDueDate.year}-${selectedDueDate.month.toString().padLeft(2, '0')}-${selectedDueDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Payment Status'),
                        items: ['Paid', 'Partial', 'Pending'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: isFullCoverage
                            ? null // Lock to Paid if full amount is covered!
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedStatus = val;
                                  });
                                }
                              },
                      ),
                      if (isFullCoverage)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '✓ Full amount covered → Status automatically set to Paid',
                              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: const InputDecoration(labelText: 'Payment Method'),
                        items: ['Cash', 'Bank Transfer', 'Card'].map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedMethod = val;
                            });
                          }
                        },
                      ),
                      if (!isFullCoverage && remainingForThis > 0) ...[
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Create new installment for remaining balance (${_formatAmount(remainingForThis, currency)})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          value: createFollowUp,
                          onChanged: (val) {
                            setState(() {
                              createFollowUp = val ?? false;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final navigator = Navigator.of(context);
                  final newDue = double.parse(amountDueController.text.trim());
                  final newPaid = double.parse(amountPaidController.text.trim());
                  final isFullyCovered = newPaid >= newDue && newDue > 0;
                  final finalStatus = isFullyCovered ? 'Paid' : selectedStatus;

                  // Save current installment update
                  await ref
                      .read(paymentRepositoryProvider)
                      .updatePaymentRecord(
                        paymentId: payment.id,
                        amountDue: newDue,
                        amountPaid: newPaid,
                        status: finalStatus,
                        paymentMethod: selectedMethod,
                        dueDate: selectedDueDate,
                      );

                  // If user selected to create a follow-up installment for the difference
                  if (!isFullyCovered && createFollowUp && (newDue - newPaid) > 0) {
                    final diff = newDue - newPaid;
                    final nextDueDate = payment.dueDate.add(const Duration(days: 14));
                    await ref
                        .read(paymentRepositoryProvider)
                        .addInstallment(
                          enrollmentId: widget.enrollment.id,
                          amountDue: diff,
                          dueDate: nextDueDate,
                          paymentMethod: selectedMethod,
                        );
                  }

                  // Refresh controllers
                  ref.invalidate(
                      enrollmentPaymentsControllerProvider(widget.enrollment.id));
                  ref.invalidate(globalPendingPaymentsControllerProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment record updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  navigator.pop();
                }
              },
              child: const Text('Save Record'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteInstallmentDialog(
      BuildContext context, WidgetRef ref, PaymentModel payment) {
    final isContractRefunded = widget.enrollment.contract?.status == 'Refunded' ||
        widget.enrollment.contract?.status == 'Cancelled';
    if (payment.status == 'Paid' ||
        payment.status == 'Refunded' ||
        isContractRefunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment.status == 'Refunded' || isContractRefunded
              ? 'Refunded installments cannot be deleted.'
              : 'Paid installments cannot be deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Installment'),
          content: const Text('Are you sure you want to delete this payment installment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref
                    .read(enrollmentPaymentsControllerProvider(widget.enrollment.id)
                        .notifier)
                    .deleteInstallment(payment.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Installment deleted.'),
                    ),
                  );
                }

                navigator.pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }



  Future<void> _generateAndShowReceipt(
    BuildContext context,
    PaymentModel payment,
    int installmentIndex,
    int totalInstallments,
  ) async {
    final student = widget.enrollment.student;
    final program = widget.enrollment.program;
    final currency = program?.currency ?? 'EUR';
    final shortId = payment.id.length > 6 ? payment.id.substring(0, 6).toUpperCase() : payment.id.toUpperCase();
    final receiptNumber = 'REC-${DateTime.now().year}-$shortId';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Uint8List? pdfBytes;

      // 1. Fetch existing stored PDF if available to retain signature & layout
      if (payment.receiptUrl != null && payment.receiptUrl!.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(payment.receiptUrl!));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            pdfBytes = res.bodyBytes;
          }
        } catch (e) {
          debugPrint('Failed to download existing receipt PDF: $e');
        }
      }

      // 2. Generate a new PDF if no existing PDF was retrieved
      if (pdfBytes == null) {
        final now = DateTime.now();
        pdfBytes = await ReceiptGeneratorService().generateReceiptPdf(
          receiptNumber: receiptNumber,
          paymentDate: now,
          studentName: student?.name ?? 'Cursant',
          studentEmail: student?.email ?? 'N/A',
          programName: program?.name ?? 'Program Mentorat',
          installmentNumber: installmentIndex,
          totalInstallments: totalInstallments,
          amountPaid: payment.amountPaid > 0 ? payment.amountPaid : payment.amountDue,
          currency: currency,
          paymentMethod: payment.paymentMethod ?? 'Bank Transfer',
          transactionReference: payment.id,
        );

        // Persist receipt PDF to Supabase Storage and database record
        try {
          await ref.read(paymentRepositoryProvider).uploadReceiptPdf(
                paymentId: payment.id,
                enrollmentId: widget.enrollment.id,
                pdfBytes: pdfBytes,
                isSigned: payment.isReceiptSigned,
              );
        } catch (_) {}
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog cleanly

        showDialog(
          context: context,
          builder: (context) => ReceiptPreviewDialog(
            pdfBytes: pdfBytes!,
            filename: 'Chitanta_$receiptNumber.pdf',
            isSigned: payment.isReceiptSigned,
            studentName: student?.name,
            studentPhone: student?.phone,
            programName: program?.name,
            amount: payment.amountPaid > 0 ? payment.amountPaid : payment.amountDue,
            currency: currency,
            installmentNumber: installmentIndex,
            totalInstallments: totalInstallments,
            receiptNumber: receiptNumber,
            receiptUrl: payment.receiptUrl,
            onSignReceipt: (signatureBytes) async {
              final signedPdfBytes = await ReceiptGeneratorService().generateReceiptPdf(
                receiptNumber: receiptNumber,
                paymentDate: DateTime.now(),
                studentName: student?.name ?? 'Cursant',
                studentEmail: student?.email ?? 'N/A',
                programName: program?.name ?? 'Program Mentorat',
                installmentNumber: installmentIndex,
                totalInstallments: totalInstallments,
                amountPaid: payment.amountPaid > 0 ? payment.amountPaid : payment.amountDue,
                currency: currency,
                paymentMethod: payment.paymentMethod ?? 'Bank Transfer',
                transactionReference: payment.id,
                mentorSignatureBytes: signatureBytes,
              );

              try {
                await ref.read(paymentRepositoryProvider).uploadReceiptPdf(
                      paymentId: payment.id,
                      enrollmentId: widget.enrollment.id,
                      pdfBytes: signedPdfBytes,
                      isSigned: true,
                    );

                // Refresh payments state so the tile updates to show Receipt Signed badge
                ref.invalidate(enrollmentPaymentsControllerProvider(widget.enrollment.id));
              } catch (_) {}

              return signedPdfBytes;
            },
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
