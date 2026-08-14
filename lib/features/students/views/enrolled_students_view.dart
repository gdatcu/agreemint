import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../programs/models/program_model.dart';
import '../../contracts/controllers/contract_controller.dart';
import '../controllers/student_controller.dart';
import '../models/enrollment_model.dart';
import '../models/student_model.dart';

class EnrolledStudentsView extends ConsumerWidget {
  final ProgramModel program;

  const EnrolledStudentsView({super.key, required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync =
        ref.watch(programEnrollmentsControllerProvider(program.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('${program.name} - Students'),
      ),
      body: enrollmentsAsync.when(
        data: (enrollments) {
          if (enrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students enrolled yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the + button below to enroll a student.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              final student = enrollment.student;

              if (student == null) return const SizedBox.shrink();

              final d = enrollment.enrollmentDate;
              final dateStr = d != null
                  ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
                  : 'N/A';

              final canDelete = enrollment.canBeDeleted;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (student.clientType != 'PF')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            student.clientType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              student.email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (student.phone != null &&
                          student.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(width: 6),
                            Text(
                              student.phone!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      if (student.cui != null && student.cui!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(width: 6),
                            Text(
                              'CUI: ${student.cui}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Enrolled: $dateStr',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          if (enrollment.contract?.status == 'Refunded' ||
                              enrollment.contract?.status == 'Cancelled') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay_rounded,
                                      size: 11, color: Colors.amber.shade900),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Refunded',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (!canDelete) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      size: 11, color: Colors.green.shade700),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Signed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.description_outlined),
                        tooltip: 'Manage Contract',
                        onPressed: () {
                          context.go(
                              '/programs/${program.id}/students/contract',
                              extra: enrollment);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.payment_outlined),
                        tooltip: 'Payments',
                        onPressed: () {
                          context.go(
                              '/programs/${program.id}/students/payments',
                              extra: enrollment);
                        },
                      ),
                      if (enrollment.contract?.status != 'Refunded' &&
                          enrollment.contract?.status != 'Cancelled')
                        IconButton(
                          icon: Icon(Icons.currency_exchange_outlined,
                              color: Colors.orange.shade700),
                          tooltip: 'Refund & Retire Client',
                          onPressed: () => _showRefundDialog(
                              context, ref, enrollment, student),
                        ),
                      if (canDelete)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade400),
                          tooltip: 'Delete Student',
                          onPressed: () => _showDeleteConfirmationDialog(
                              context, ref, enrollment, student),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.lock_outline,
                              color: Colors.grey.shade400),
                          tooltip: 'Cannot delete: Active signed contract',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cannot delete student while contract is active. Process a refund/cancellation first.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
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
                    programEnrollmentsControllerProvider(program.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEnrollStudentDialog(context, ref),
        tooltip: 'Enroll New Student',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  void _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    EnrollmentModel enrollment,
    StudentModel student,
  ) {
    final formKey = GlobalKey<FormState>();
    final initialPrice = program.totalPrice;
    final reasonController = TextEditingController(
        text: 'Client requested withdrawal / refund within guarantee period.');
    final amountController =
        TextEditingController(text: initialPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.currency_exchange_outlined, color: Colors.orange.shade800),
              const SizedBox(width: 10),
              const Text('Process Refund & Retirement'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student: ${student.name} (${student.email})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Program: ${program.name}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Refund Amount (${program.currency})',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter refund amount';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Please enter a valid numeric amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Refund Reason / Notes',
                      hintText: 'e.g., Requested withdrawal within 5 days',
                    ),
                    maxLines: 2,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a refund reason';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final navigator = Navigator.of(context);
                  final refundAmount = double.parse(amountController.text.trim());
                  final refundReason = reasonController.text.trim();

                  await ref
                      .read(enrollmentContractControllerProvider(enrollment.id)
                          .notifier)
                      .cancelAndRefundContract(
                        refundReason: refundReason,
                        refundAmount: refundAmount,
                      );

                  ref.invalidate(
                      programEnrollmentsControllerProvider(program.id));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Contract for ${student.name} marked as Refunded.'),
                        backgroundColor: Colors.orange.shade800,
                      ),
                    );
                  }

                  navigator.pop();
                }
              },
              child: const Text('Process Refund'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    EnrollmentModel enrollment,
    StudentModel student,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 10),
              const Text('Delete Student'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${student.name} (${student.email}) from ${program.name}?\n\nThis will remove their enrollment and any unsigned contract.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(programEnrollmentsControllerProvider(program.id)
                        .notifier)
                    .removeStudentEnrollment(
                      enrollmentId: enrollment.id,
                      studentId: student.id,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Student ${student.name} deleted.'),
                      backgroundColor: Colors.red.shade800,
                    ),
                  );
                }
              },
              child: const Text('Delete Student'),
            ),
          ],
        );
      },
    );
  }

  void _showEnrollStudentDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final cuiController = TextEditingController();
    final regComController = TextEditingController();
    final billingAddressController = TextEditingController();
    String clientType = 'PF';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Enroll New Student'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'PF',
                              label: Text('PF (Individual)'),
                              icon: Icon(Icons.person_outline),
                            ),
                            ButtonSegment<String>(
                              value: 'PFA',
                              label: Text('PFA / Company'),
                              icon: Icon(Icons.business_outlined),
                            ),
                          ],
                          selected: {clientType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setStateDialog(() {
                              clientType = newSelection.first;
                            });
                          },
                        ),
                      ),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: clientType == 'PF'
                              ? 'Full Name'
                              : 'Company / PFA Name',
                          hintText: clientType == 'PF'
                              ? 'e.g., Jane Doe'
                              : 'e.g., Acme Tech PFA / SRL',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g., jane.doe@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          final emailRegExp =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          hintText: 'e.g., +15551234567',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      if (clientType != 'PF') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cuiController,
                          decoration: const InputDecoration(
                            labelText: 'CUI / CIF',
                            hintText: 'e.g., RO12345678',
                          ),
                          validator: (value) {
                            if (clientType != 'PF' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter CUI / CIF for PFA / Company';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: regComController,
                          decoration: const InputDecoration(
                            labelText: 'Reg. Com. (Optional)',
                            hintText: 'e.g., F40/123/2026 or J40/1234/2025',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: billingAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Billing Address (Optional)',
                            hintText: 'e.g., Str. Exemplu Nr. 10, Bucuresti',
                          ),
                        ),
                      ],
                    ],
                  ),
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
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final cui = cuiController.text.trim();
                      final regCom = regComController.text.trim();
                      final billingAddress = billingAddressController.text.trim();

                      await ref
                          .read(programEnrollmentsControllerProvider(program.id)
                              .notifier)
                          .addAndEnrollStudent(
                            name: name,
                            email: email,
                            phone: phone.isNotEmpty ? phone : null,
                            clientType: clientType,
                            cui: cui.isNotEmpty ? cui : null,
                            regCom: regCom.isNotEmpty ? regCom : null,
                            billingAddress:
                                billingAddress.isNotEmpty ? billingAddress : null,
                          );

                      // Show success snackbar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student enrolled successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      navigator.pop();
                    }
                  },
                  child: const Text('Enroll'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
