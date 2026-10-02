import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../programs/models/program_model.dart';
import '../../contracts/controllers/contract_controller.dart';
import '../controllers/student_controller.dart';
import '../models/enrollment_model.dart';
import '../models/student_model.dart';
import '../../../core/services/celebration_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/services/anaf_service.dart';
import '../../../core/widgets/copyable_text.dart';
import 'certificate_preview_dialog.dart';
import 'widgets/edit_student_dialog.dart';

class EnrolledStudentsView extends ConsumerStatefulWidget {
  final ProgramModel program;

  const EnrolledStudentsView({super.key, required this.program});

  @override
  ConsumerState<EnrolledStudentsView> createState() =>
      _EnrolledStudentsViewState();
}

class _EnrolledStudentsViewState extends ConsumerState<EnrolledStudentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Signed', 'Unsigned', 'No Plan', 'Missing SOLO', 'Fully Paid', 'Refunded', 'Retired', 'Archived'
  String _selectedSort =
      'Enrolled: Newest First'; // 'Enrolled: Newest First', 'Enrolled: Oldest First', 'Signed Date: Newest First', 'Name: A-Z'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EnrollmentModel> _filterAndSortEnrollments(
      List<EnrollmentModel> enrollments) {
    final list = enrollments.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final student = e.student;
        if (student == null) return false;
        final matchesName = student.name.toLowerCase().contains(q);
        final matchesEmail = student.email.toLowerCase().contains(q);
        final matchesPhone = (student.phone?.toLowerCase() ?? '').contains(q);
        final matchesCui = (student.cui?.toLowerCase() ?? '').contains(q);
        final matchesRegCom = (student.regCom?.toLowerCase() ?? '').contains(q);
        if (!matchesName &&
            !matchesEmail &&
            !matchesPhone &&
            !matchesCui &&
            !matchesRegCom) {
          return false;
        }
      }

      if (_selectedFilter == 'Signed') {
        return e.isSignedByBeneficiary;
      } else if (_selectedFilter == 'Unsigned') {
        return !e.isSignedByBeneficiary && !e.isRetired;
      } else if (_selectedFilter == 'Fully Paid') {
        return e.isFullyPaid;
      } else if (_selectedFilter == 'No Plan') {
        return !e.hasPaymentPlan;
      } else if (_selectedFilter == 'Missing SOLO') {
        return e.hasMissingSoloInvoice;
      } else if (_selectedFilter == 'Refunded') {
        return e.contract?.status == 'Refunded' || e.contract?.status == 'Cancelled';
      } else if (_selectedFilter == 'Archived') {
        return e.contract?.status == 'Archived';
      } else if (_selectedFilter == 'Sărbători') {
        final st = e.student;
        if (st == null) return false;
        final celebrations =
            CelebrationService.getUpcomingCelebrations([st], daysAhead: 365);
        return celebrations.isNotEmpty;
      } else if (_selectedFilter == 'Retired') {

        return e.isRetired;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (_selectedSort == 'Enrolled: Oldest First') {
        final aDate = a.enrollmentDate ?? DateTime(1970);
        final bDate = b.enrollmentDate ?? DateTime(1970);
        return aDate.compareTo(bDate);
      } else if (_selectedSort == 'Signed Date: Newest First') {
        final aDate = a.signedDate ?? DateTime(1970);
        final bDate = b.signedDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      } else if (_selectedSort == 'Name: A-Z') {
        final aName = a.student?.name.toLowerCase() ?? '';
        final bName = b.student?.name.toLowerCase() ?? '';
        return aName.compareTo(bName);
      } else {
        // Enrolled: Newest First (default)
        final aDate = a.enrollmentDate ?? DateTime(1970);
        final bDate = b.enrollmentDate ?? DateTime(1970);
        return bDate.compareTo(aDate);
      }
    });

    return list;
  }

  void _showCelebrationsDialog(
      BuildContext context, List<StudentModel> students) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final allCelebrations =
            CelebrationService.getUpcomingCelebrations(students, daysAhead: 365);

        return AlertDialog(
          title: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Calendar Sărbătoriți & Onomastică',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${allCelebrations.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            height: 480,
            child: allCelebrations.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nu au fost găsite zile de naștere sau onomastici pentru cursanții din acest program.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: allCelebrations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final c = allCelebrations[i];
                      final isToday = c.isToday;
                      final isTomorrow = c.isTomorrow;
                      final icon =
                          c.type == CelebrationType.birthday ? '🎂' : '🌸';
                      final dateFormatted =
                          '${c.date.day.toString().padLeft(2, '0')}.${c.date.month.toString().padLeft(2, '0')}.${c.date.year}';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isToday
                              ? Colors.green.shade100
                              : (c.type == CelebrationType.birthday
                                  ? Colors.amber.shade100
                                  : Colors.purple.shade100),
                          child: Text(icon, style: const TextStyle(fontSize: 16)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Colors.green.shade600
                                    : (isTomorrow
                                        ? Colors.amber.shade700
                                        : (c.daysUntil <= 30
                                            ? Colors.blueGrey.shade700
                                            : Colors.grey.shade600)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.relativeLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${c.title} • $dateFormatted',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        trailing: (c.student.phone != null &&
                                c.student.phone!.isNotEmpty)
                            ? IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                tooltip: 'Felicită pe WhatsApp',
                                onPressed: () async {
                                  final msg = CelebrationService
                                      .generateGreetingMessage(c);
                                  await WhatsAppService.sendCelebrationGreeting(
                                    phone: c.student.phone!,
                                    message: msg,
                                  );
                                },
                              )
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Închide'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(
      List<EnrollmentModel> enrollments, List<StudentModel> students) {
    final totalCount = enrollments.length;
    final signedCount =
        enrollments.where((e) => e.isSignedByBeneficiary).length;
    final noPlanCount = enrollments.where((e) => !e.hasPaymentPlan).length;
    final fullyPaidCount = enrollments.where((e) => e.isFullyPaid).length;
    final retiredCount = enrollments.where((e) => e.isRetired).length;
    final upcomingCelebrationsCount =
        CelebrationService.getUpcomingCelebrations(students, daysAhead: 365).length;


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Total', '$totalCount', Icons.people_alt, Colors.blue),
          const SizedBox(width: 8),
          _buildStatCard('Signed', '$signedCount', Icons.verified, Colors.green),
          const SizedBox(width: 8),
          _buildStatCard('No Plan', '$noPlanCount', Icons.warning_amber_rounded, Colors.red),
          const SizedBox(width: 8),
          _buildStatCard('Fully Paid', '$fullyPaidCount', Icons.payments, Colors.teal),
          const SizedBox(width: 8),
          _buildStatCard('Retired', '$retiredCount', Icons.replay_rounded, Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard(
            'Sărbători',
            '$upcomingCelebrationsCount',
            Icons.cake_rounded,
            Colors.amber.shade800,
            onTap: () => _showCelebrationsDialog(context, students),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? color : color.withAlpha(220),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _selectedFilter == label;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildCelebrationsBanner(
      List<CelebrationEvent> celebrations, List<StudentModel> students) {
    if (celebrations.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayCount = celebrations.where((c) => c.isToday).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2213) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFFD97706).withAlpha(120)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todayCount > 0
                      ? 'Sărbătoriți Astăzi & În Următoarele Zile'
                      : 'Următoarele Zile de Naștere & Onomastice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showCelebrationsDialog(context, students),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Vezi tot (${celebrations.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: celebrations.map((e) {
                final isToday = e.isToday;
                final isTomorrow = e.isTomorrow;
                final icon = e.type == CelebrationType.birthday ? '🎂' : '🌸';
                final student = e.student;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isToday
                            ? const Color(0xFF451A03)
                            : const Color(0xFF1E293B))
                        : (isToday ? const Color(0xFFFEF3C7) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFFF59E0B)
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                student.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Colors.green.shade600
                                      : (isTomorrow
                                          ? Colors.amber.shade700
                                          : Colors.blueGrey.shade600),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.relativeLabel,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (student.phone != null &&
                          student.phone!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final msg =
                                CelebrationService.generateGreetingMessage(e);
                            await WhatsAppService.sendCelebrationGreeting(
                              phone: student.phone!,
                              message: msg,
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.green.shade500
                                  .withAlpha(isDark ? 50 : 30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync =
        ref.watch(programEnrollmentsControllerProvider(widget.program.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.program.name} - Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cake_rounded, color: Colors.amber),
            tooltip: 'Calendar Sărbătoriți & Onomastică',
            onPressed: () {
              final students = enrollmentsAsync.value
                      ?.map((e) => e.student)
                      .whereType<StudentModel>()
                      .toList() ??
                  [];
              _showCelebrationsDialog(context, students);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Students',
            onSelected: (val) {
              setState(() {
                _selectedSort = val;
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'Enrolled: Newest First',
                child: Text('Enrolled: Newest First'),
              ),
              PopupMenuItem(
                value: 'Enrolled: Oldest First',
                child: Text('Enrolled: Oldest First'),
              ),
              PopupMenuItem(
                value: 'Signed Date: Newest First',
                child: Text('Signed Date: Newest First'),
              ),
              PopupMenuItem(
                value: 'Name: A-Z',
                child: Text('Name: A-Z'),
              ),
            ],
          ),
        ],
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

          final students = enrollments.map((e) {
            final st = e.student;
            if (st == null) return null;
            // Fallback: If student cui (CNP) is empty on student row, look in contract details
            if ((st.cui == null || st.cui!.isEmpty) &&
                e.contract?.details != null) {
              final cnpFromContract =
                  e.contract!.details!['cnp_cursant'] as String?;
              if (cnpFromContract != null && cnpFromContract.isNotEmpty) {
                return StudentModel(
                  id: st.id,
                  name: st.name,
                  email: st.email,
                  phone: st.phone,
                  createdAt: st.createdAt,
                  clientType: st.clientType,
                  cui: cnpFromContract,
                  regCom: st.regCom,
                  billingAddress: st.billingAddress,
                );
              }
            }
            return st;
          }).whereType<StudentModel>().toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.checkAndNotifyCelebrations(students);
          });

          final upcomingCelebrations =
              CelebrationService.getUpcomingCelebrations(students, daysAhead: 365);
          final filtered = _filterAndSortEnrollments(enrollments);


          return Column(
            children: [
              // Summary Header Cards
              _buildSummaryHeader(enrollments, students),

              // Upcoming Celebrations Banner (Birthdays & Name Days)
              _buildCelebrationsBanner(upcomingCelebrations, students),

              // Live Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by Name, Email, Phone, CUI/CIF...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withAlpha(80),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filter Chips & Results Count Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Signed'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Unsigned'),
                            const SizedBox(width: 6),
                            _buildFilterChip('No Plan'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Missing SOLO'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Fully Paid'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Sărbători'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Refunded'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Retired'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Archived'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Showing ${filtered.length} of ${enrollments.length} students',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedFilter = 'All';
                          });
                        },
                        child: Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Student List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No students found matching "$_searchQuery"'
                                    : 'No students matching "$_selectedFilter" filter',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset Search & Filters'),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedFilter = 'All';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final enrollment = filtered[index];
                          final student = enrollment.student;

                          if (student == null) return const SizedBox.shrink();

                          final d = enrollment.enrollmentDate;
                          final dateStr = d != null
                              ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
                              : 'N/A';

                          final canDelete = enrollment.canBeDeleted;
                          final isSigned = enrollment.isSignedByBeneficiary;
                          final isFullyPaid = enrollment.isFullyPaid;
                          final payments = enrollment.payments ?? [];

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        child: Text(
                                          student.name.isNotEmpty
                                              ? student.name[0].toUpperCase()
                                              : 'S',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: CopyableText(
                                                    text: student.name,
                                                    label: 'Nume',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                                if (student.clientType != 'PF') ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                          color: Colors.blue.shade200),
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
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            CopyableText(
                                              text: student.email,
                                              label: 'Email',
                                              icon: Icons.email_outlined,
                                            ),
                                            if (student.phone != null &&
                                                student.phone!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              CopyableText(
                                                text: student.phone!,
                                                label: 'Telefon',
                                                icon: Icons.phone_outlined,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (upcomingCelebrations
                                      .any((c) => c.student.id == student.id)) ...[
                                    const SizedBox(height: 8),
                                    ...upcomingCelebrations
                                        .where((c) => c.student.id == student.id)
                                        .map((c) => Container(
                                              margin:
                                                  const EdgeInsets.only(bottom: 4),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: c.isToday
                                                    ? Colors.amber.shade100
                                                    : Colors.amber.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.amber.shade400,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    c.type ==
                                                            CelebrationType
                                                                .birthday
                                                        ? '🎂'
                                                        : '🌸',
                                                    style: const TextStyle(
                                                        fontSize: 13),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      '${c.title} (${c.relativeLabel})',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.amber.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                  if (student.phone != null &&
                                                      student
                                                          .phone!.isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () async {
                                                        final msg = CelebrationService
                                                            .generateGreetingMessage(
                                                                c);
                                                        await WhatsAppService
                                                            .sendCelebrationGreeting(
                                                          phone: student.phone!,
                                                          message: msg,
                                                        );
                                                      },
                                                      child: const Icon(
                                                        Icons
                                                            .chat_bubble_outline_rounded,
                                                        size: 13,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            )),
                                  ],
                                  const SizedBox(height: 10),

                                  // Status Badges Row (Contract + Payments)

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Enrolled: $dateStr',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),

                                      // Contract Badge (Interactive: Tapping navigates to contract)
                                      if (enrollment.isRetired)
                                        _buildBadge(
                                          icon: Icons.replay_rounded,
                                          label: 'Retired',
                                          bgColor: Colors.amber.shade50,
                                          borderColor: Colors.amber.shade300,
                                          textColor: Colors.amber.shade900,
                                          tooltip: 'Click to view retired contract details',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/contract',
                                              extra: enrollment,
                                            );
                                          },
                                        )
                                      else if (isSigned)
                                        _buildBadge(
                                          icon: Icons.verified,
                                          label: 'Signed',
                                          bgColor: Colors.green.shade50,
                                          borderColor: Colors.green.shade200,
                                          textColor: Colors.green.shade800,
                                          tooltip: 'Click to view / manage signed contract',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/contract',
                                              extra: enrollment,
                                            );
                                          },
                                        )
                                      else
                                        _buildBadge(
                                          icon: Icons.hourglass_empty,
                                          label: 'Unsigned',
                                          bgColor: Colors.orange.shade50,
                                          borderColor: Colors.orange.shade200,
                                          textColor: Colors.orange.shade900,
                                          tooltip: 'Click to create / sign contract',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/contract',
                                              extra: enrollment,
                                            );
                                          },
                                        ),

                                      // Payment Status Badge (Interactive: Tapping navigates to payments)
                                      if (isFullyPaid)
                                        _buildBadge(
                                          icon: Icons.check_circle_outline,
                                          label: 'Fully Paid',
                                          bgColor: Colors.teal.shade50,
                                          borderColor: Colors.teal.shade200,
                                          textColor: Colors.teal.shade900,
                                          tooltip: 'Click to view payment history',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/payments',
                                              extra: enrollment,
                                            );
                                          },
                                        )
                                      else if (payments.isNotEmpty)
                                        _buildBadge(
                                          icon: Icons.payments_outlined,
                                          label:
                                              '${enrollment.paidInstallmentsCount}/${payments.length} Paid',
                                          bgColor: Colors.purple.shade50,
                                          borderColor: Colors.purple.shade200,
                                          textColor: Colors.purple.shade900,
                                          tooltip: 'Click to manage payment plan',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/payments',
                                              extra: enrollment,
                                            );
                                          },
                                        )
                                      else
                                        _buildBadge(
                                          icon: Icons.warning_amber_rounded,
                                          label: 'No Payment Plan',
                                          bgColor: Colors.red.shade50,
                                          borderColor: Colors.red.shade300,
                                          textColor: Colors.red.shade900,
                                          tooltip: 'Click to generate payment plan',
                                          onTap: () {
                                            context.go(
                                              '/programs/${widget.program.id}/students/payments',
                                              extra: enrollment,
                                            );
                                          },
                                        ),

                                      // Granular SOLO Invoice Badge (Interactive: Tapping opens breakdown dialog)
                                      if (payments.isNotEmpty) ...[
                                        if (enrollment.soloInvoicesCount == payments.length)
                                          _buildBadge(
                                            icon: Icons.receipt_long_outlined,
                                            label:
                                                '${enrollment.soloInvoicesCount}/${payments.length} SOLO',
                                            bgColor: Colors.green.shade50,
                                            borderColor: Colors.green.shade200,
                                            textColor: Colors.green.shade800,
                                            tooltip:
                                                'All SOLO invoices attached. Click for breakdown',
                                            onTap: () => _showSoloBreakdownDialog(
                                                context, enrollment, student),
                                          )
                                        else if (enrollment.paidMissingSoloInvoicesCount > 0)
                                          _buildBadge(
                                            icon: Icons.warning_amber_rounded,
                                            label:
                                                '${enrollment.soloInvoicesCount}/${payments.length} SOLO (${enrollment.paidMissingSoloInvoicesCount} Missing)',
                                            bgColor: Colors.orange.shade50,
                                            borderColor: Colors.orange.shade300,
                                            textColor: Colors.orange.shade900,
                                            tooltip:
                                                'Missing SOLO invoices for paid installments. Click to inspect',
                                            onTap: () => _showSoloBreakdownDialog(
                                                context, enrollment, student),
                                          )
                                        else
                                          _buildBadge(
                                            icon: Icons.receipt_long_outlined,
                                            label:
                                                '${enrollment.soloInvoicesCount}/${payments.length} SOLO',
                                            bgColor: Colors.blueGrey.shade50,
                                            borderColor: Colors.blueGrey.shade200,
                                            textColor: Colors.blueGrey.shade800,
                                            tooltip:
                                                'Click to inspect SOLO invoice breakdown',
                                            onTap: () => _showSoloBreakdownDialog(
                                                context, enrollment, student),
                                          ),
                                      ],
                                    ],
                                  ),
                                  const Divider(height: 16),
                                   Wrap(
                                     alignment: WrapAlignment.end,
                                     crossAxisAlignment:
                                         WrapCrossAlignment.center,
                                     spacing: 2,
                                     runSpacing: 2,
                                     children: [
                                       IconButton(
                                         icon: const Icon(
                                             Icons.workspace_premium_rounded,
                                             color: Colors.amber),
                                         tooltip: 'Graduation Certificate (PDF)',
                                         onPressed: () {
                                           showDialog(
                                             context: context,
                                             builder: (ctx) =>
                                                 CertificatePreviewDialog(
                                               student: student,
                                               program: widget.program,
                                             ),
                                           );
                                         },
                                       ),
                                       IconButton(
                                         icon: const Icon(Icons.description_outlined),
                                         tooltip: 'Manage Contract',
                                         onPressed: () {
                                           context.go(
                                               '/programs/${widget.program.id}/students/contract',
                                               extra: enrollment);
                                         },
                                       ),
                                       IconButton(
                                         icon: const Icon(Icons.payment_outlined),
                                         tooltip: 'Payments',
                                         onPressed: () {
                                           context.go(
                                               '/programs/${widget.program.id}/students/payments',
                                               extra: enrollment);
                                         },
                                       ),
                                       IconButton(
                                         icon: Icon(Icons.chat_bubble_outline,
                                             color: Colors.green.shade600),
                                         tooltip: 'WhatsApp Follow-Up',
                                         onPressed: () async {
                                           try {
                                             await WhatsAppService
                                                 .sendGeneralFollowUp(
                                               phone: student.phone ?? '',
                                               name: student.name,
                                             );
                                           } catch (_) {
                                             if (context.mounted) {
                                               ScaffoldMessenger.of(context)
                                                   .showSnackBar(
                                                 const SnackBar(
                                                   content: Text(
                                                       'Could not open WhatsApp. Ensure it is installed and the phone number is valid.'),
                                                   backgroundColor: Colors.red,
                                                 ),
                                               );
                                             }
                                           }
                                         },
                                       ),
                                       IconButton(
                                         icon: Icon(Icons.person_add_alt_1_outlined,
                                             color: Colors.blue.shade700),
                                         tooltip: 'Copiază date client SOLO',
                                         onPressed: () => _copySoloClientData(student),
                                       ),
                                       IconButton(
                                         icon: const Icon(Icons.edit_outlined),
                                         tooltip: 'Editează Nume & Date Cursant',
                                         onPressed: () => EditStudentDialog.show(
                                           context,
                                           student: student,
                                           programId: widget.program.id,
                                         ),
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
                                          onPressed: () =>
                                              _showDeleteConfirmationDialog(
                                                  context, ref, enrollment, student),
                                        )
                                      else
                                        IconButton(
                                          icon: Icon(Icons.lock_outline,
                                              color: Colors.grey.shade400),
                                          tooltip:
                                              'Cannot delete: Active signed contract',
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Cannot delete student with active signed contract or payment history.'),
                                              ),
                                            );
                                          },
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
                    programEnrollmentsControllerProvider(widget.program.id)),
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

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: textColor),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        child: child,
      );
    }
    return child;
  }

  void _showSoloBreakdownDialog(
    BuildContext context,
    EnrollmentModel enrollment,
    StudentModel student,
  ) {
    final payments = enrollment.payments ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.blue.shade800),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SOLO Invoices — ${student.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Installment SOLO Invoice Status (${enrollment.soloInvoicesCount}/${payments.length} Attached):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (payments.isEmpty)
                    const Text('No payment schedule created for this student yet.')
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = payments[index];
                        final hasInvoice = p.externalInvoiceNumber != null &&
                            p.externalInvoiceNumber!.isNotEmpty;
                        final isPaid = p.status == 'Paid';

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasInvoice
                                ? Colors.green.shade50
                                : (isPaid ? Colors.orange.shade50 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasInvoice
                                  ? Colors.green.shade200
                                  : (isPaid
                                      ? Colors.orange.shade300
                                      : Colors.grey.shade300),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Installment #${index + 1}: ${p.amountDue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.shade100
                                          : Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid
                                            ? Colors.green.shade900
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (hasInvoice)
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SOLO Invoice: ${p.externalInvoiceNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                )
                              else if (isPaid)
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 14, color: Colors.orange.shade800),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Paid — Missing SOLO Invoice',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(Icons.hourglass_empty,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pending Payment — No Invoice',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Manage Payments & Invoices'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(
                  '/programs/${widget.program.id}/students/payments',
                  extra: enrollment,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    EnrollmentModel enrollment,
    StudentModel student,
  ) {
    final formKey = GlobalKey<FormState>();
    final initialPrice = widget.program.totalPrice;
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
                  Text('Program: ${widget.program.name}'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Refund Amount (${widget.program.currency})',
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
                      programEnrollmentsControllerProvider(widget.program.id));

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
            'Are you sure you want to delete ${student.name} (${student.email}) from ${widget.program.name}?\n\nThis will remove their enrollment and any unsigned contract.',
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
                    .read(programEnrollmentsControllerProvider(widget.program.id)
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
    final smartTextController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final cuiController = TextEditingController();
    final regComController = TextEditingController();
    final billingAddressController = TextEditingController();
    final ciSerieController = TextEditingController();
    final ciEliberatorController = TextEditingController();
    String clientType = 'PF';
    bool isAnafLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> lookupAnaf() async {
              final rawCui = cuiController.text.trim();
              if (rawCui.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Introduceți mai întâi un CUI / CIF pentru interogare.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setStateDialog(() => isAnafLoading = true);
              try {
                final details = await AnafService.lookupCompany(rawCui);
                setStateDialog(() {
                  cuiController.text = details.cui;
                  if (nameController.text.trim().isEmpty) {
                    nameController.text = details.denumire;
                  }
                  if (details.nrRegCom.isNotEmpty) {
                    regComController.text = details.nrRegCom;
                  }
                  if (details.adresa.isNotEmpty) {
                    billingAddressController.text = details.adresa;
                  }
                  if (details.telefon != null &&
                      phoneController.text.trim().isEmpty) {
                    phoneController.text = details.telefon!;
                  }
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ANAF: ${details.denumire} • ${details.tvaBadge}${details.isInactiv ? ' • ⚠️ INACTIV' : ''}',
                      ),
                      backgroundColor: details.isInactiv
                          ? Colors.deepOrange
                          : Colors.green[700],
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setStateDialog(() => isAnafLoading = false);
              }
            }

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
                      // Smart Paste Expander/Card
                      ExpansionTile(
                        title: Row(
                          children: const [
                            Icon(Icons.bolt, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Smart Paste (WhatsApp / Text)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          TextField(
                            controller: smartTextController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Pasează mesajul de pe WhatsApp aici...\n(Nume, CNP, Email, Adresă)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                            ),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Autofill Form'),
                            onPressed: () {
                              setStateDialog(() {
                                _parseSmartText(
                                  text: smartTextController.text,
                                  nameCtrl: nameController,
                                  emailCtrl: emailController,
                                  phoneCtrl: phoneController,
                                  cuiCtrl: cuiController,
                                  regComCtrl: regComController,
                                  addressCtrl: billingAddressController,
                                  ciSerieCtrl: ciSerieController,
                                  ciEliberatorCtrl: ciEliberatorController,
                                  onClientTypeChanged: (type) {
                                    clientType = type;
                                  },
                                );
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter email address';
                          }
                          if (!val.contains('@')) {
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
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cuiController,
                        decoration: InputDecoration(
                          labelText: clientType == 'PF' ? 'CNP (Optional)' : 'CUI / CIF (Optional)',
                          hintText: clientType == 'PF' ? 'e.g., 1900101...' : 'e.g., RO12345678',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          suffixIcon: clientType != 'PF'
                              ? (isAnafLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search, color: Colors.blue),
                                      tooltip: 'Caută date companie în ANAF',
                                      onPressed: lookupAnaf,
                                    ))
                              : null,
                        ),
                      ),
                      if (clientType == 'PF') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: ciSerieController,
                                decoration: const InputDecoration(
                                  labelText: 'Serie și Nr. CI (Optional)',
                                  prefixIcon: Icon(Icons.credit_card_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: ciEliberatorController,
                                decoration: const InputDecoration(
                                  labelText: 'Eliberat de (Optional)',
                                  prefixIcon: Icon(Icons.gavel_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (clientType == 'PFA') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: regComController,
                          decoration: const InputDecoration(
                            labelText: 'Reg. Com. (Optional)',
                            hintText: 'e.g., F40/123/2026 or J40/1234/2025',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: billingAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Billing Address (Optional)',
                          hintText: 'e.g., Str. Exemplu Nr. 10, Bucuresti',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
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
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final cui = cuiController.text.trim();
                      final regCom = regComController.text.trim();
                      final billingAddress = billingAddressController.text.trim();
                      final ciSerie = ciSerieController.text.trim();
                      final ciEliberator = ciEliberatorController.text.trim();
                      var finalAddress = billingAddress;
                      if (clientType == 'PF' && (ciSerie.isNotEmpty || ciEliberator.isNotEmpty)) {
                        finalAddress = '$billingAddress | $ciSerie | $ciEliberator';
                      }

                      await ref
                          .read(programEnrollmentsControllerProvider(widget.program.id)
                              .notifier)
                          .addAndEnrollStudent(
                            name: name,
                            email: email,
                            phone: phone.isNotEmpty ? phone : null,
                            clientType: clientType,
                            cui: cui.isNotEmpty ? cui : null,
                            regCom: regCom.isNotEmpty ? regCom : null,
                            billingAddress:
                                finalAddress.isNotEmpty ? finalAddress : null,
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

  void _parseSmartText({
    required String text,
    required TextEditingController nameCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController cuiCtrl,
    required TextEditingController regComCtrl,
    required TextEditingController addressCtrl,
    required TextEditingController ciSerieCtrl,
    required TextEditingController ciEliberatorCtrl,
    required Function(String) onClientTypeChanged,
  }) {
    final lines = text.split('\n');

    for (var line in lines) {
      // Clean up bullet points, asterisks, hyphens, and leading whitespace
      var cleanLine = line.trim();
      while (cleanLine.startsWith('*') ||
          cleanLine.startsWith('-') ||
          cleanLine.startsWith('•') ||
          cleanLine.startsWith(' ')) {
        cleanLine = cleanLine.substring(1).trim();
      }

      if (cleanLine.isEmpty) continue;

      // Find the first colon to split key and value
      final colonIndex = cleanLine.indexOf(':');
      if (colonIndex == -1) {
        // Fallback: If no colon, but it's an email, extract it
        if (cleanLine.contains('@')) {
          final emailMatch = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(cleanLine);
          if (emailMatch != null) {
            emailCtrl.text = emailMatch.group(0) ?? '';
          }
        }
        // Fallback: If it's a CNP (13 digits), extract it
        final cnpMatch = RegExp(r'\b[12569][0-9]{12}\b').firstMatch(cleanLine);
        if (cnpMatch != null) {
          cuiCtrl.text = cnpMatch.group(0) ?? '';
          onClientTypeChanged('PF');
        }
        continue;
      }

      final key = cleanLine.substring(0, colonIndex).trim().toLowerCase();
      final value = cleanLine.substring(colonIndex + 1).trim();

      if (value.isEmpty) continue;

      // Match keys
      if (key.contains('nume complet') ||
          key.contains('nume') ||
          key.contains('full name') ||
          key.contains('client')) {
        nameCtrl.text = value;
      } else if (key.contains('email') || value.contains('@')) {
        // Remove trailing/leading braces or symbols often found around emails
        emailCtrl.text = value.replaceAll(RegExp(r'[<>\[\]]'), '').trim();
      } else if (key.contains('telefon') || key.contains('phone')) {
        phoneCtrl.text = value.replaceAll(RegExp(r'[\s\-]'), '');
      } else if (key.contains('cnp') || key.contains('cod numeric')) {
        cuiCtrl.text = value;
        onClientTypeChanged('PF');
      } else if (key.contains('cui') || key.contains('cif')) {
        cuiCtrl.text = value.replaceAll(' ', '').toUpperCase();
        onClientTypeChanged('PFA');
      } else if (key.contains('reg. com') ||
          key.contains('reg com') ||
          key.contains('nr. reg')) {
        regComCtrl.text = value.toUpperCase();
        onClientTypeChanged('PFA');
      } else if (key.contains('ci ') ||
          key.contains('ci(') ||
          key.contains('carte') ||
          key.contains('serie') ||
          key.contains('număr') ||
          key.contains('numar')) {
        ciSerieCtrl.text = value;
      } else if (key.contains('eliberat') || key.contains('spclep')) {
        ciEliberatorCtrl.text = value;
      } else if ((key.contains('adresa') ||
              key.contains('adresă') ||
              key.contains('address')) &&
          !key.contains('email')) {
        addressCtrl.text = value;
      }
    }
  }

  Future<void> _copySoloClientData(StudentModel student) async {
    var cleanAddress = student.billingAddress ?? '';
    if (cleanAddress.contains(' | ')) {
      cleanAddress = cleanAddress.split(' | ')[0].trim();
    }
    final clientData = {
      'clientName': student.name,
      'clientCnp': student.cui ?? '',
      'clientAddress': cleanAddress,
      'clientEmail': student.email,
      'clientPhone': student.phone ?? '',
    };
    try {
      await Clipboard.setData(ClipboardData(text: jsonEncode(clientData)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datele clientului pentru SOLO au fost copiate! Deschide "Adaugă client nou" în SOLO și apasă "Autofill Client Nou".'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copierea a eșuat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
