import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/certificate_generator_service.dart';
import '../../settings/controllers/business_settings_controller.dart';
import '../models/student_model.dart';
import '../../programs/models/program_model.dart';

class CertificatePreviewDialog extends ConsumerWidget {
  final StudentModel student;
  final ProgramModel program;

  const CertificatePreviewDialog({
    super.key,
    required this.student,
    required this.program,
  });

  Future<void> _sendWhatsAppCertificateNotification(
      BuildContext context) async {
    final phone = student.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    final cleanPhone =
        phone.startsWith('0') ? '40${phone.substring(1)}' : phone;

    final message =
        'Felicitări, ${student.name}! 🎓✨\n\n'
        'Ai absolvit cu succes programul de mentorat "${program.name}" la QualiAdept!\n\n'
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
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.read(businessSettingsControllerProvider).asData?.value ??
            ref.read(businessSettingsControllerProvider).value;

    final certService = CertificateGeneratorService();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                        'Graduation Certificate - ${student.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Program: ${program.name}',
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
            const Divider(height: 20),
            Expanded(
              child: PdfPreview(
                build: (format) => certService.generateCertificatePdf(
                  studentName: student.name,
                  programName: program.name,
                  completionDate: DateTime.now(),
                  courseHours: 120,
                  mentorSignatureBytes: settings?.mentorSignatureBytes,
                  mentorName: settings?.companyName ?? 'DATCU GEORGE-CRISTIAN',
                ),
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                initialPageFormat: PdfPageFormat.a4.landscape,
                pdfFileName:
                    'Certificat_Absolvire_${student.name.replaceAll(' ', '_')}.pdf',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                const SizedBox(width: 12),
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
