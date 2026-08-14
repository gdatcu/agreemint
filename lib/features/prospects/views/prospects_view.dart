import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../programs/controllers/program_controller.dart';
import '../../programs/models/program_model.dart';
import '../controllers/prospect_controller.dart';
import '../models/prospect_model.dart';
import '../../../core/services/whatsapp_reminder_service.dart';

class ProspectsView extends ConsumerStatefulWidget {
  const ProspectsView({super.key});

  @override
  ConsumerState<ProspectsView> createState() => _ProspectsViewState();
}

class _ProspectsViewState extends ConsumerState<ProspectsView> {
  String _selectedFilter = 'Due / Overdue'; // 'Due / Overdue', 'Upcoming', 'Converted', 'All'

  @override
  Widget build(BuildContext context) {
    final prospectsState = ref.watch(prospectsControllerProvider);
    final programsState = ref.watch(programControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prospect Follow-ups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Prospect',
            onPressed: () => _showAddEditProspectDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Due / Overdue'),
                const SizedBox(width: 8),
                _buildFilterChip('Upcoming'),
                const SizedBox(width: 8),
                _buildFilterChip('Converted'),
                const SizedBox(width: 8),
                _buildFilterChip('All'),
              ],
            ),
          ),

          Expanded(
            child: prospectsState.when(
              data: (prospects) {
                final filtered = _filterProspects(prospects);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_paused_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No prospects in "$_selectedFilter"',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a new lead to follow up with.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddEditProspectDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Prospect'),
                        ),
                      ],
                    ),
                  );
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final prospect = filtered[index];

                    final dueLocalDate = DateTime(prospect.followUpDate.year,
                        prospect.followUpDate.month, prospect.followUpDate.day);
                    final diffDays =
                        dueLocalDate.difference(today).inDays;
                    final isOverdue = diffDays < 0 && prospect.status != 'Converted';
                    final isDueToday = diffDays == 0 && prospect.status != 'Converted';

                    final relativeText = isOverdue
                        ? '${diffDays.abs()} days overdue'
                        : isDueToday
                            ? 'Due today'
                            : 'Due in $diffDays days';

                    final badgeColor = prospect.status == 'Converted'
                        ? Colors.green
                        : (isOverdue
                            ? Colors.red
                            : (isDueToday ? Colors.orange : Colors.blue));

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
                                  prospect.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  prospect.status == 'Converted'
                                      ? 'Converted'
                                      : relativeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (prospect.program != null)
                                Text(
                                  'Interested in: ${prospect.program!.name}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              if (prospect.notes != null &&
                                  prospect.notes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '📝 ${prospect.notes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Follow-up: ${dueLocalDate.toString().split(' ')[0]}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (prospect.phone != null &&
                                      prospect.phone!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.phone,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      prospect.phone!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // WhatsApp Outreach Button
                              IconButton(
                                icon: Icon(Icons.chat_outlined,
                                    size: 20, color: Colors.green.shade600),
                                tooltip: 'Send WhatsApp Message',
                                onPressed: () {
                                  WhatsAppReminderService.sendProspectFollowUp(
                                    context: context,
                                    phone: prospect.phone,
                                    prospectName: prospect.name,
                                    programName: prospect.program?.name,
                                  );
                                },
                              ),
                              // Convert to Enrolled Student Button
                              if (prospect.status != 'Converted')
                                IconButton(
                                  icon: const Icon(Icons.school,
                                      size: 20, color: Colors.indigo),
                                  tooltip: 'Convert to Enrolled Student',
                                  onPressed: () => _showConvertToStudentDialog(
                                      context, ref, prospect, programsState.value ?? []),
                                ),
                              // Edit Button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Prospect',
                                onPressed: () => _showAddEditProspectDialog(
                                    context, ref, prospect: prospect),
                              ),
                              // Delete Button
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.redAccent),
                                tooltip: 'Delete Prospect',
                                onPressed: () =>
                                    _showDeleteProspectDialog(context, ref, prospect),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = _selectedFilter == filterName;
    return FilterChip(
      label: Text(filterName),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filterName;
        });
      },
    );
  }

  List<ProspectModel> _filterProspects(List<ProspectModel> prospects) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 'Due / Overdue':
        return prospects.where((p) {
          if (p.status == 'Converted') return false;
          final due = DateTime(
              p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
          return due.isBefore(today) || due.isAtSameMomentAs(today);
        }).toList();

      case 'Upcoming':
        return prospects.where((p) {
          if (p.status == 'Converted') return false;
          final due = DateTime(
              p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
          return due.isAfter(today);
        }).toList();

      case 'Converted':
        return prospects.where((p) => p.status == 'Converted').toList();

      case 'All':
      default:
        return prospects;
    }
  }

  void _showAddEditProspectDialog(BuildContext context, WidgetRef ref,
      {ProspectModel? prospect}) {
    final isEdit = prospect != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: prospect?.name ?? '');
    final phoneController = TextEditingController(text: prospect?.phone ?? '');
    final emailController = TextEditingController(text: prospect?.email ?? '');
    final notesController = TextEditingController(text: prospect?.notes ?? '');

    String? selectedProgramId = prospect?.programId;
    DateTime selectedDate = prospect?.followUpDate ?? DateTime.now().add(const Duration(days: 2));
    String selectedStatus = prospect?.status ?? 'Pending';

    final programsState = ref.read(programControllerProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Prospect' : 'Add Prospect / Lead'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Prospect Name *',
                          hintText: 'e.g., Ion Popescu',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter prospect name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., +40722571081',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g., ion@example.com',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      programsState.when(
                        data: (programs) {
                          return DropdownButtonFormField<String>(
                            value: selectedProgramId,
                            decoration: const InputDecoration(
                              labelText: 'Program of Interest',
                              prefixIcon: Icon(Icons.school),
                            ),
                            items: programs.map((prog) {
                              return DropdownMenuItem(
                                value: prog.id,
                                child: Text(prog.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedProgramId = val;
                              });
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Conversation Status',
                          hintText: 'e.g., Said they will decide next Friday...',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
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
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Follow-up Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag),
                          ),
                          items: ['Pending', 'Contacted', 'Converted', 'Lost']
                              .map((st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedStatus = val;
                              });
                            }
                          },
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
                      final phone = phoneController.text.trim();
                      final email = emailController.text.trim();
                      final notes = notesController.text.trim();

                      if (isEdit) {
                        await ref
                            .read(prospectsControllerProvider.notifier)
                            .updateProspect(
                              prospectId: prospect.id,
                              name: name,
                              phone: phone.isEmpty ? null : phone,
                              email: email.isEmpty ? null : email,
                              programId: selectedProgramId,
                              notes: notes.isEmpty ? null : notes,
                              followUpDate: selectedDate,
                              status: selectedStatus,
                            );
                      } else {
                        await ref
                            .read(prospectsControllerProvider.notifier)
                            .addProspect(
                              name: name,
                              phone: phone.isEmpty ? null : phone,
                              email: email.isEmpty ? null : email,
                              programId: selectedProgramId,
                              notes: notes.isEmpty ? null : notes,
                              followUpDate: selectedDate,
                            );
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit
                                ? 'Prospect updated successfully!'
                                : 'Prospect added!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }

                      navigator.pop();
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add Prospect'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConvertToStudentDialog(
    BuildContext context,
    WidgetRef ref,
    ProspectModel prospect,
    List<ProgramModel> programs,
  ) {
    if (programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a program cohort first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String selectedProgramId = prospect.programId ?? programs.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Convert Prospect to Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enroll "${prospect.name}" directly into a program cohort:',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedProgramId,
                    decoration: const InputDecoration(
                      labelText: 'Select Program Cohort',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: programs.map((prog) {
                      return DropdownMenuItem(
                        value: prog.id,
                        child: Text(prog.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedProgramId = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await ref
                        .read(prospectsControllerProvider.notifier)
                        .convertToStudent(
                          prospect: prospect,
                          programId: selectedProgramId,
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${prospect.name} successfully enrolled as a student!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }

                    navigator.pop();
                  },
                  child: const Text('Enroll Student'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteProspectDialog(
      BuildContext context, WidgetRef ref, ProspectModel prospect) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Prospect'),
          content: Text(
              'Are you sure you want to delete "${prospect.name}" from your follow-ups list?'),
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
                    .read(prospectsControllerProvider.notifier)
                    .deleteProspect(prospect.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prospect deleted.')),
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
