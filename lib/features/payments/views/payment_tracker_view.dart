import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/models/enrollment_model.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
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
          final totalDue =
              payments.fold<double>(0, (sum, p) => sum + p.amountDue);
          final totalPaid =
              payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
          final remaining = (totalDue - totalPaid) > 0 ? (totalDue - totalPaid) : 0.0;

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
                                fontSize: 15,
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

                    // Determine effective display status
                    final isFullyPaid = payment.amountPaid >= payment.amountDue && payment.amountDue > 0;
                    final displayStatus = isFullyPaid ? 'Paid' : payment.status;

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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                          ],
                        ),
                        onTap: () =>
                            _showRecordPaymentDialog(context, ref, payment),
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

  void _showRecordPaymentDialog(
      BuildContext context, WidgetRef ref, PaymentModel payment) {
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
}
