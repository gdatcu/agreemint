import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/contract_controller.dart';
import '../models/contract_model.dart';
import '../../../core/constants.dart';
import '../../../core/services/whatsapp_reminder_service.dart';

class UnsignedContractsView extends ConsumerWidget {
  const UnsignedContractsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(globalContractsControllerProvider);

    return Scaffold(
      body: contractsAsync.when(
        data: (contracts) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final unsignedContracts = contracts.where((c) {
            final isSigned = c.status == 'FullySigned' ||
                c.status == 'Signed' ||
                (c.clientSignatureUrl != null && c.clientSignatureUrl!.isNotEmpty) ||
                (c.signedPdfUrl != null && c.signedPdfUrl!.isNotEmpty);
            final isArchived = c.status == 'Cancelled' || c.status == 'Refunded';
            return !isSigned && !isArchived;
          }).toList();

          if (unsignedContracts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, size: 64, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Toate contractele sunt semnate!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nu există contracte generate care așteaptă semnătura cursantului.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: unsignedContracts.length,
            itemBuilder: (context, index) {
              final contract = unsignedContracts[index];
              final createdLocalDate = DateTime(contract.createdDate.year, contract.createdDate.month, contract.createdDate.day);
              final daysPending = today.difference(createdLocalDate).inDays;
              final createdStr = contract.createdDate.toLocal().toString().split(' ')[0];

              final daysText = daysPending == 0
                  ? 'Generat astăzi'
                  : (daysPending == 1
                      ? 'Generat ieri (1 zi)'
                      : 'Așteaptă semnătura de $daysPending zile');

              final signingWebUrl = '${AppConstants.clientPortalBaseUrl}${contract.id}';
              final rawPdfUrl = contract.pdfUrl ?? contract.signedPdfUrl ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: daysPending > 0 ? Colors.orange.shade300 : Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contract.studentName ?? 'Cursant',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contract.programName ?? 'Program Mentorat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: daysPending > 0 ? Colors.orange.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: daysPending > 0 ? Colors.orange.shade400 : Colors.blue.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  daysPending > 0 ? Icons.access_time_filled : Icons.edit_document,
                                  size: 14,
                                  color: daysPending > 0 ? Colors.orange.shade800 : Colors.blue.shade800,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  daysText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: daysPending > 0 ? Colors.orange.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Data Generare: $createdStr',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          if (contract.contractNumber > 0) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.tag, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              contract.contractNumberStr,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: () {
                              WhatsAppReminderService.sendContractFollowUp(
                                context: context,
                                phone: contract.studentPhone,
                                studentName: contract.studentName ?? 'Cursant',
                                programName: contract.programName ?? 'Program Mentorat',
                                createdDateStr: createdStr,
                                contractSigningUrl: signingWebUrl,
                              );
                            },
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Send WhatsApp Follow-Up'),
                          ),
                          const SizedBox(width: 8),
                          if (rawPdfUrl.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () => launchUrl(Uri.parse(rawPdfUrl)),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('PDF'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Copiază Link Semnătură',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: signingWebUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Linkul de semnare s-a copiat în clipboard!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Eroare la încărcarea contractelor: $err'),
        ),
      ),
    );
  }
}
