import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/certificate_generator_service.dart';
import '../../settings/controllers/business_settings_controller.dart';
import '../models/student_model.dart';
import '../../programs/models/program_model.dart';

class CertificatePreviewDialog extends ConsumerStatefulWidget {
  final StudentModel student;
  final ProgramModel program;

  const CertificatePreviewDialog({
    super.key,
    required this.student,
    required this.program,
  });

  @override
  ConsumerState<CertificatePreviewDialog> createState() =>
      _CertificatePreviewDialogState();
}

class _CertificatePreviewDialogState
    extends ConsumerState<CertificatePreviewDialog> {
  late TextEditingController _hoursController;
  late TextEditingController _sessionsController;
  late TextEditingController _sessionDurationController;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '50');
    _sessionsController = TextEditingController(text: '20');
    _sessionDurationController = TextEditingController(text: '2.5');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _sessionsController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppCertificateNotification(
      BuildContext context) async {
    final phone = widget.student.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final cleanPhone =
        phone.startsWith('0') ? '40${phone.substring(1)}' : phone;

    final hours = _hoursController.text.trim();
    final message =
        'Felicitări, ${widget.student.name}! 🎓✨\n\n'
        'Ai absolvit cu succes programul de mentorat "${widget.program.name}" ($hours ore de consultanță & pregătire) la QualiAdept!\n\n'
        'Certificatul tău oficial de absolvire a fost generat și este disponibil. Îți mulțumim pentru implicare și îți dorim mult succes în carieră! 🚀';

    final encodedMsg = Uri.encodeComponent(message);
    final urlStr = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encodedMsg'
        : 'https://wa.me/?text=$encodedMsg';

    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(businessSettingsControllerProvider);
    final settings = settingsState.asData?.value ?? settingsState.value;

    final certService = CertificateGeneratorService();

    final hours = int.tryParse(_hoursController.text.trim()) ?? 50;
    final sessions = int.tryParse(_sessionsController.text.trim()) ?? 20;

    final hasSignature =
        settings?.mentorSignatureBytes != null &&
            settings!.mentorSignatureBytes!.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 920,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dialog Header Row
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Graduation Certificate - ${widget.student.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Program: ${widget.program.name}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Controls Bar (Customizable Hours & Sessions + Signature Alert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 6),
                      const Text('Hours Spent:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 56,
                        height: 36,
                        child: TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sessions:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        height: 36,
                        child: TextField(
                          controller: _sessionsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Hrs/Session:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 52,
                        height: 36,
                        child: TextField(
                          controller: _sessionDurationController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (!hasSignature)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.draw_rounded, size: 16),
                      label: const Text('Add Signature in Settings',
                          style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/settings');
                      },
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Signature Embedded',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Live PDF Certificate Preview
            Expanded(
              child: PdfPreview(
                key: ValueKey(
                    'cert_${hours}_${sessions}_${_sessionDurationController.text}'),
                build: (format) => certService.generateCertificatePdf(
                  studentName: widget.student.name,
                  programName: widget.program.name,
                  completionDate: DateTime.now(),
                  courseHours: hours,
                  sessionCount: sessions,
                  sessionDuration:
                      _sessionDurationController.text.trim().isNotEmpty
                          ? _sessionDurationController.text.trim()
                          : '2.5',
                  mentorSignatureBytes: settings?.mentorSignatureBytes,
                  mentorName: settings?.companyName ?? 'DATCU GEORGE-CRISTIAN',
                ),
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                initialPageFormat: PdfPageFormat.a4.landscape,
                pdfFileName:
                    'Certificat_Absolvire_${widget.student.name.replaceAll(' ', '_')}.pdf',
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Actions Row
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Send WhatsApp Congratulation'),
                  onPressed: () =>
                      _sendWhatsAppCertificateNotification(context),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
