import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/models/enrollment_model.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../../../core/services/frankfurter_service.dart';

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
                      'No Payment Plan Generated',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a payment schedule for the mentorship fee.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showGeneratePlanDialog(context, ref),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Generate Payment Plan'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate summary stats
          final totalDue =
              payments.fold<double>(0, (sum, p) => sum + p.amountDue);
          final totalPaid =
              payments.fold<double>(0, (sum, p) => sum + p.amountPaid);

          return Column(
            children: [
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            width: 1,
                            height: 40,
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Container(
                            width: 1,
                            height: 40,
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
                              _formatAmount(totalDue - totalPaid, currency),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (totalDue - totalPaid) > 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                                color: _getStatusColor(payment.status)
                                    .withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                payment.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(payment.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Due: ${_formatAmount(payment.amountDue, currency)}'),
                                Text(
                                    'Paid: ${_formatAmount(payment.amountPaid, currency)}',
                                    style:
                                        const TextStyle(color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due Date: $dateStr',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
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
                        onTap: payment.status != 'Paid'
                            ? () =>
                                _showRecordPaymentDialog(context, ref, payment)
                            : null,
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

  void _showRecordPaymentDialog(
      BuildContext context, WidgetRef ref, PaymentModel payment) {
    final currency = widget.enrollment.program?.currency ?? 'RON';
    final formKey = GlobalKey<FormState>();
    final remainingBalance = payment.amountDue - payment.amountPaid;
    final amountController = TextEditingController(
        text: remainingBalance.toString());
    String selectedMethod = 'Cash';
    String selectedStatus = 'Paid';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount Received ($currency)',
                        hintText: 'e.g., 500.00',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount greater than 0';
                        }
                        if (amount > remainingBalance) {
                          return 'Amount cannot exceed remaining balance';
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
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration:
                          const InputDecoration(labelText: 'Payment Status'),
                      items: ['Paid', 'Partial'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedStatus = val;
                          });
                        }
                      },
                    ),
                  ],
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
                  final enteredAmount =
                      double.parse(amountController.text.trim());

                  // Calculate new amountPaid
                  final newAmountPaid = payment.amountPaid + enteredAmount;

                  await ref
                      .read(enrollmentPaymentsControllerProvider(widget.enrollment.id)
                          .notifier)
                      .logPayment(
                        paymentId: payment.id,
                        amountPaid: newAmountPaid,
                        status: selectedStatus,
                        paymentMethod: selectedMethod,
                      );

                  // Show success snackbar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment logged successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  navigator.pop();
                }
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }
}
