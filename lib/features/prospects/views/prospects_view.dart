import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../programs/controllers/program_controller.dart';
import '../../programs/models/program_model.dart';
import '../controllers/prospect_controller.dart';
import '../models/prospect_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/whatsapp_reminder_service.dart';

class ProspectsView extends ConsumerStatefulWidget {
  const ProspectsView({super.key});

  @override
  ConsumerState<ProspectsView> createState() => _ProspectsViewState();
}

class _ProspectsViewState extends ConsumerState<ProspectsView> {
  String _selectedFilter = 'Due / Overdue'; // 'Due / Overdue', 'Upcoming', 'Contacted', 'Converted', 'Lost', 'All'
  String _searchQuery = '';
  String _sortBy = 'Earliest Follow-up'; // 'Earliest Follow-up', 'Latest Follow-up', 'Name (A-Z)', 'Recently Added'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prospectsState = ref.watch(prospectsControllerProvider);
    final programsState = ref.watch(programControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prospect Follow-ups & Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Prospect',
            onPressed: () => _showAddEditProspectDialog(context, ref),
          ),
        ],
      ),
      body: prospectsState.when(
        data: (prospects) {
          // Trigger daily background push alert evaluation for prospect follow-ups
          NotificationService.checkAndNotifyProspectFollowUps(prospects);

          final filtered = _filterAndSortProspects(prospects);

          // Metrics calculation
          final totalLeads = prospects.length;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final overdueCount = prospects.where((p) {
            if (p.status == 'Converted' || p.status == 'Lost') return false;
            final due = DateTime(p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
            return due.isBefore(today) || due.isAtSameMomentAs(today);
          }).length;

          final upcomingCount = prospects.where((p) {
            if (p.status == 'Converted' || p.status == 'Lost') return false;
            final due = DateTime(
                p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
            return due.isAfter(today);
          }).length;

          final contactedCount = prospects.where((p) => p.status == 'Contacted').length;
          final convertedCount = prospects.where((p) => p.status == 'Converted').length;
          final lostCount = prospects.where((p) => p.status == 'Lost').length;
          final conversionRate = totalLeads > 0
              ? (convertedCount / totalLeads * 100).toStringAsFixed(0)
              : '0';

          return Column(
            children: [
              // KPI Summary Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildKpiCard('Total Leads', '$totalLeads', Colors.blue,
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All')),
                    const SizedBox(width: 8),
                    _buildKpiCard('Due / Overdue', '$overdueCount', Colors.orange,
                        isSelected: _selectedFilter == 'Due / Overdue',
                        onTap: () => setState(() => _selectedFilter = 'Due / Overdue')),
                    const SizedBox(width: 8),
                    _buildKpiCard('Contacted', '$contactedCount', Colors.purple,
                        isSelected: _selectedFilter == 'Contacted',
                        onTap: () => setState(() => _selectedFilter = 'Contacted')),
                    const SizedBox(width: 8),
                    _buildKpiCard('Converted', '$convertedCount ($conversionRate%)', Colors.green,
                        isSelected: _selectedFilter == 'Converted',
                        onTap: () => setState(() => _selectedFilter = 'Converted')),
                    const SizedBox(width: 8),
                    _buildKpiCard('Lost', '$lostCount', Colors.grey,
                        isSelected: _selectedFilter == 'Lost',
                        onTap: () => setState(() => _selectedFilter = 'Lost')),
                  ],
                ),
              ),

              // Search & Sort Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, phone...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort_rounded, size: 20),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Earliest Follow-up', child: Text('Earliest Due')),
                        DropdownMenuItem(
                            value: 'Latest Follow-up', child: Text('Latest Due')),
                        DropdownMenuItem(value: 'Name (A-Z)', child: Text('Name A-Z')),
                        DropdownMenuItem(
                            value: 'Recently Added', child: Text('Newest')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ],
                ),
              ),

              // Filter Chips Row with Live Item Counts
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildFilterChip('Due / Overdue', overdueCount),
                    const SizedBox(width: 6),
                    _buildFilterChip('Upcoming', upcomingCount),
                    const SizedBox(width: 6),
                    _buildFilterChip('Contacted', contactedCount),
                    const SizedBox(width: 6),
                    _buildFilterChip('Converted', convertedCount),
                    const SizedBox(width: 6),
                    _buildFilterChip('Lost', lostCount),
                    const SizedBox(width: 6),
                    _buildFilterChip('All', totalLeads),
                  ],
                ),
              ),

              // Prospects List View
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No prospects found in "$_selectedFilter"',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search query.'
                                  : 'Tap + to add a new lead to your pipeline.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final prospect = filtered[index];
                          final dueLocalDate = DateTime(
                              prospect.followUpDate.year,
                              prospect.followUpDate.month,
                              prospect.followUpDate.day);
                          final diffDays = dueLocalDate.difference(today).inDays;
                          final isOverdue = diffDays < 0 &&
                              prospect.status != 'Converted' &&
                              prospect.status != 'Lost';
                          final isDueToday = diffDays == 0 &&
                              prospect.status != 'Converted' &&
                              prospect.status != 'Lost';

                          final relativeText = isOverdue
                              ? '${diffDays.abs()} days overdue'
                              : isDueToday
                                  ? 'Due today'
                                  : 'Due in $diffDays days';

                          final badgeColor = prospect.status == 'Converted'
                              ? Colors.green
                              : prospect.status == 'Lost'
                                  ? Colors.grey.shade600
                                  : prospect.status == 'Contacted'
                                      ? Colors.purple
                                      : (isOverdue
                                          ? Colors.red
                                          : (isDueToday
                                              ? Colors.orange
                                              : Colors.blue));

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isOverdue
                                    ? Colors.red.withAlpha(128)
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                width: isOverdue ? 1.0 : 0.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          prospect.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: badgeColor.withAlpha(100)),
                                        ),
                                        child: Text(
                                          prospect.status == 'Converted'
                                              ? 'Converted'
                                              : prospect.status == 'Lost'
                                                  ? 'Lost'
                                                  : prospect.status ==
                                                          'Contacted'
                                                      ? 'Contacted ($relativeText)'
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
                                  const SizedBox(height: 6),
                                  if (prospect.program != null)
                                    Text(
                                      'Interested in: ${prospect.program!.name}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (prospect.notes != null &&
                                      prospect.notes!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '📝 ${prospect.notes}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Follow-up: ${dueLocalDate.toString().split(' ')[0]}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                      if (prospect.phone != null &&
                                          prospect.phone!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone,
                                                size: 14,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              prospect.phone!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 16),

                                  // Quick Action Buttons Row
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      // 1-Tap Log Contact & Reschedule
                                      IconButton(
                                        icon: Icon(Icons.phone_callback_rounded,
                                            size: 20,
                                            color: Colors.purple.shade600),
                                        tooltip: 'Log Contact & Set Follow-up',
                                        onPressed: () =>
                                            _showLogContactDialog(
                                                context, ref, prospect),
                                      ),

                                      // WhatsApp Outreach Button
                                      IconButton(
                                        icon: Icon(Icons.chat_outlined,
                                            size: 20,
                                            color: Colors.green.shade600),
                                        tooltip: 'Send WhatsApp Message',
                                        onPressed: () {
                                          WhatsAppReminderService
                                              .sendProspectFollowUp(
                                            context: context,
                                            phone: prospect.phone,
                                            prospectName: prospect.name,
                                            programName:
                                                prospect.program?.name,
                                          );
                                        },
                                      ),

                                      // Convert to Enrolled Student Button
                                      if (prospect.status != 'Converted')
                                        IconButton(
                                          icon: const Icon(Icons.school,
                                              size: 20, color: Colors.indigo),
                                          tooltip:
                                              'Convert to Enrolled Student',
                                          onPressed: () =>
                                              _showConvertToStudentDialog(
                                                  context,
                                                  ref,
                                                  prospect,
                                                  programsState.value ?? []),
                                        ),

                                      // Quick Mark as Lost / Toggle Lost
                                      IconButton(
                                        icon: Icon(
                                            prospect.status == 'Lost'
                                                ? Icons.restore_rounded
                                                : Icons.do_not_disturb_on_outlined,
                                            size: 20,
                                            color: prospect.status == 'Lost'
                                                ? Colors.amber.shade700
                                                : Colors.grey.shade600),
                                        tooltip: prospect.status == 'Lost'
                                            ? 'Reactivate Prospect (Set to Pending)'
                                            : 'Mark as Lost',
                                        onPressed: () =>
                                            _toggleLostStatus(context, ref, prospect),
                                      ),

                                      // Edit Button
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        tooltip: 'Edit Prospect',
                                        onPressed: () =>
                                            _showAddEditProspectDialog(
                                                context, ref,
                                                prospect: prospect),
                                      ),

                                      // Delete Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 20, color: Colors.redAccent),
                                        tooltip: 'Delete Prospect',
                                        onPressed: () =>
                                            _showDeleteProspectDialog(
                                                context, ref, prospect),
                                      ),
                                    ],
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
        error: (err, _) => Center(child: Text('Error loading prospects: $err')),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color,
      {bool isSelected = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(35) : color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(60),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterName, int count) {
    final isSelected = _selectedFilter == filterName;
    return FilterChip(
      label: Text('$filterName ($count)', style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filterName;
        });
      },
    );
  }

  List<ProspectModel> _filterAndSortProspects(List<ProspectModel> prospects) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<ProspectModel> filtered = prospects.where((p) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(query);
        final phoneMatch = p.phone?.toLowerCase().contains(query) ?? false;
        final emailMatch = p.email?.toLowerCase().contains(query) ?? false;
        final progMatch =
            p.program?.name.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !phoneMatch && !emailMatch && !progMatch) return false;
      }
      return true;
    }).toList();

    switch (_selectedFilter) {
      case 'Due / Overdue':
        filtered = filtered.where((p) {
          if (p.status == 'Converted' || p.status == 'Lost') return false;
          final due = DateTime(
              p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
          return due.isBefore(today) || due.isAtSameMomentAs(today);
        }).toList();
        break;

      case 'Upcoming':
        filtered = filtered.where((p) {
          if (p.status == 'Converted' || p.status == 'Lost') return false;
          final due = DateTime(
              p.followUpDate.year, p.followUpDate.month, p.followUpDate.day);
          return due.isAfter(today);
        }).toList();
        break;

      case 'Contacted':
        filtered = filtered.where((p) => p.status == 'Contacted').toList();
        break;

      case 'Converted':
        filtered = filtered.where((p) => p.status == 'Converted').toList();
        break;

      case 'Lost':
        filtered = filtered.where((p) => p.status == 'Lost').toList();
        break;

      case 'All':
      default:
        break;
    }

    // Sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Latest Follow-up':
          return b.followUpDate.compareTo(a.followUpDate);
        case 'Name (A-Z)':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Recently Added':
          return b.createdAt.compareTo(a.createdAt);
        case 'Earliest Follow-up':
        default:
          return a.followUpDate.compareTo(b.followUpDate);
      }
    });

    return filtered;
  }

  void _showLogContactDialog(
      BuildContext context, WidgetRef ref, ProspectModel prospect) {
    final newNoteController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final existingNotes = prospect.notes?.trim() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final formattedDate =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

            return AlertDialog(
              title: Text('Log Contact - ${prospect.name}'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (existingNotes.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.history, size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('Previous Conversation History:',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 120),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              existingNotes,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const Text('Add New Update / Note Entry:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: newNoteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g., Discussed requirements on phone, requested info...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Set Next Follow-up Date:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Quick Date Preset Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('+2 Days'),
                            onPressed: () {
                              setState(() {
                                selectedDate =
                                    DateTime.now().add(const Duration(days: 2));
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('+7 Days'),
                            onPressed: () {
                              setState(() {
                                selectedDate =
                                    DateTime.now().add(const Duration(days: 7));
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Next Week'),
                            onPressed: () {
                              setState(() {
                                selectedDate =
                                    DateTime.now().add(const Duration(days: 14));
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
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
                            labelText: 'Custom Follow-up Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(formattedDate,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save & Mark Contacted'),
                  onPressed: () async {
                    final navigator = Navigator.pop;
                    final newEntry = newNoteController.text.trim();
                    final now = DateTime.now();
                    final dateTag =
                        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

                    String finalNotes = existingNotes;
                    if (newEntry.isNotEmpty) {
                      final formattedEntry = '[$dateTag] $newEntry';
                      finalNotes = existingNotes.isNotEmpty
                          ? '$existingNotes\n$formattedEntry'
                          : formattedEntry;
                    }

                    await ref
                        .read(prospectsControllerProvider.notifier)
                        .updateProspect(
                          prospectId: prospect.id,
                          name: prospect.name,
                          phone: prospect.phone,
                          email: prospect.email,
                          programId: prospect.programId,
                          notes: finalNotes.isNotEmpty ? finalNotes : null,
                          followUpDate: selectedDate,
                          status: 'Contacted',
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Logged contact & updated follow-up for ${prospect.name} to $formattedDate'),
                          backgroundColor: Colors.purple.shade700,
                        ),
                      );
                    }
                    navigator(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleLostStatus(
      BuildContext context, WidgetRef ref, ProspectModel prospect) async {
    final newStatus = prospect.status == 'Lost' ? 'Pending' : 'Lost';

    await ref.read(prospectsControllerProvider.notifier).updateProspect(
          prospectId: prospect.id,
          name: prospect.name,
          phone: prospect.phone,
          email: prospect.email,
          programId: prospect.programId,
          notes: prospect.notes,
          followUpDate: prospect.followUpDate,
          status: newStatus,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'Lost'
              ? 'Marked "${prospect.name}" as Lost.'
              : 'Reactivated "${prospect.name}" to Pending.'),
          backgroundColor:
              newStatus == 'Lost' ? Colors.grey.shade800 : Colors.green.shade700,
        ),
      );
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
    DateTime selectedDate =
        prospect?.followUpDate ?? DateTime.now().add(const Duration(days: 2));
    String selectedStatus = prospect?.status ?? 'Pending';

    final programsState = ref.read(programControllerProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(isEdit ? 'Edit Prospect' : 'Add Prospect / Lead'),
                  ),
                ],
              ),
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
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Program of Interest',
                              prefixIcon: Icon(Icons.school),
                            ),
                            items: programs.map((prog) {
                              return DropdownMenuItem(
                                value: prog.id,
                                child: Text(
                                  prog.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Lead Status',
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
