import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/program_controller.dart';
import '../models/program_model.dart';
import '../../analytics/controllers/analytics_controller.dart';

class ProgramsView extends ConsumerWidget {
  const ProgramsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsState = ref.watch(programControllerProvider);

    // Listen for state changes to display SnackBars for errors
    ref.listen(programControllerProvider, (previous, next) {
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
        title: const Text('Mentoring Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'Archived Program History',
            onPressed: () => _showHistoryDialog(context, ref),
          ),
        ],
      ),
      body: programsState.when(
        data: (programs) {
          if (programs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No programs created yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to launch one!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
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
                  onTap: () {
                    context.go('/programs/${program.id}/students',
                        extra: program);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    program.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (program.description != null &&
                          program.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          program.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Total Price: ${formatCurrencyAmount(program.totalPrice, program.currency)}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Program',
                        onPressed: () {
                          _showProgramFormDialog(context, ref, program: program);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Program',
                        onPressed: () {
                          _showDeleteConfirmDialog(context, ref, program);
                        },
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline,
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
                onPressed: () => ref.invalidate(programControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProgramFormDialog(context, ref),
        tooltip: 'Launch New Program',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProgramFormDialog(BuildContext context, WidgetRef ref,
      {ProgramModel? program}) {
    final isEditing = program != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: program?.name ?? '');
    final descriptionController =
        TextEditingController(text: program?.description ?? '');
    final priceController = TextEditingController(
        text: program != null ? program.totalPrice.toStringAsFixed(2) : '');
    String selectedCurrency = program?.currency ?? 'RON';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Program Details' : 'Launch New Program'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Program Name',
                      hintText: 'e.g., Elite Flutter Mentorship',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter program name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Describe the program goals or timeline',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Total Price',
                            hintText: 'e.g., 1500.00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price < 0) {
                              return 'Please enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'RON', child: Text('RON')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              selectedCurrency = val;
                            }
                          },
                        ),
                      ),
                    ],
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
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final navigator = Navigator.of(context);
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  final price = double.parse(priceController.text.trim());

                  if (isEditing) {
                    await ref
                        .read(programControllerProvider.notifier)
                        .updateProgram(
                          id: program.id,
                          name: name,
                          description:
                              description.isNotEmpty ? description : null,
                          totalPrice: price,
                          currency: selectedCurrency,
                        );
                  } else {
                    await ref
                        .read(programControllerProvider.notifier)
                        .addProgram(
                          name: name,
                          description:
                              description.isNotEmpty ? description : null,
                          totalPrice: price,
                          currency: selectedCurrency,
                        );
                  }

                  navigator.pop();
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, ProgramModel program) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive & Delete Program?'),
          content: Text(
            'Are you sure you want to delete "${program.name}"?\n\nAll program details, student enrollments, contracts, and payment records will be safely archived into History Tables for audit purposes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref
                    .read(programControllerProvider.notifier)
                    .deleteProgram(program.id);
                navigator.pop();
              },
              child: const Text('Archive & Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final historyAsync = ref.watch(programHistoryProvider);

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.history_edu, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('Archived Program History'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: historyAsync.when(
                  data: (historyList) {
                    if (historyList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No archived program records yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: historyList.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = historyList[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.description ?? "No description"}\nTotal Price: ${item.totalPrice.toStringAsFixed(2)} RON',
                          ),
                          trailing: const Chip(
                            label: Text('Archived', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Text(
                    'Error loading history: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
