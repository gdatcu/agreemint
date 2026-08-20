import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppReminderService {
  /// Cleans a phone number by stripping spaces, dashes, parentheses, and leading plus.
  static String cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      // Default Romanian local number 07xx xxx xxx -> 407xx xxx xxx
      cleaned = '40${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Extracts the last 4 digits of a phone number for the document security PIN notice.
  static String extractPinFromPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '****';
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length >= 4) {
      return cleaned.substring(cleaned.length - 4);
    }
    return cleaned.isNotEmpty ? cleaned : '****';
  }

  /// Wraps a raw document PDF URL inside the Agreemint PIN Gateway Web Viewer URL.
  static String buildDocGatewayUrl({
    required String rawPdfUrl,
    required String? studentPhone,
    required String docTitle,
    String? customBaseUrl,
  }) {
    final pin = extractPinFromPhone(studentPhone);
    final encodedUrl = Uri.encodeComponent(rawPdfUrl.trim());
    final encodedTitle = Uri.encodeComponent(docTitle.trim());

    final baseUrl = (customBaseUrl != null && customBaseUrl.trim().isNotEmpty)
        ? customBaseUrl.trim()
        : 'https://agreemint.qualiadept.eu/';

    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '${cleanBase}#/view-doc?url=$encodedUrl&pin=$pin&title=$encodedTitle';
  }

  /// Builds an objective, formal payment notification in Romanian from QualiAdept Billing Bot.
  static String buildReminderMessage({
    required String studentName,
    required String programName,
    required double amount,
    required String currency,
    required String dueDateStr,
    bool isDueTomorrow = false,
    String dueStage = 'overdue',
    int? daysUntilDue,
    String? invoiceUrl,
    String? invoiceNumber,
    String? contractPdfUrl,
    String? studentPhone,
  }) {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';

    String dueText;
    if (isDueTomorrow || dueStage == 'tomorrow' || daysUntilDue == 1) {
      dueText = 'are scadența *mâine, $dueDateStr*';
    } else if (dueStage == 'today' || daysUntilDue == 0) {
      dueText = 'are scadența *astăzi, $dueDateStr*';
    } else if (daysUntilDue != null && daysUntilDue > 1) {
      dueText = 'are scadența în *$daysUntilDue zile* (pe *$dueDateStr*)';
    } else {
      dueText = 'a înregistrat scadența pe data de *$dueDateStr*';
    }

    final pin = extractPinFromPhone(studentPhone);
    final pinNotice = (studentPhone != null && studentPhone.trim().isNotEmpty)
        ? '\n🔐 *PIN Securitate Document:* Ultimele 4 cifre ale numărului tău de telefon (*$pin*)'
        : '';

    final docsList = <String>[];
    if (invoiceUrl != null && invoiceUrl.trim().isNotEmpty) {
      final invNumText = (invoiceNumber != null && invoiceNumber.trim().isNotEmpty)
          ? ' ($invoiceNumber)'
          : '';
      final gatewayInvoiceUrl = buildDocGatewayUrl(
        rawPdfUrl: invoiceUrl,
        studentPhone: studentPhone,
        docTitle: 'Factură Fiscală SOLO$invNumText',
      );
      docsList.add('\u{1F4C4} *Factură fiscală (SOLO)$invNumText:* $gatewayInvoiceUrl$pinNotice');
    }
    if (contractPdfUrl != null && contractPdfUrl.trim().isNotEmpty) {
      final gatewayContractUrl = buildDocGatewayUrl(
        rawPdfUrl: contractPdfUrl,
        studentPhone: studentPhone,
        docTitle: 'Contract de servicii semnat',
      );
      docsList.add('\u{270D}\u{FE0F} *Contract de servicii semnat:* $gatewayContractUrl$pinNotice');
    }

    final docsSection = docsList.isNotEmpty ? '\n\n${docsList.join('\n\n')}' : '';

    return '\u{1F916} *[Notificare Automată - QualiAdept Billing]*\n\n'
        'Stimate/ă *$studentName*,\n\n'
        'Vă transmitem acest mesaj pentru a vă reaminti că tranșa aferentă programului *$programName*, în valoare de *$amountFormatted*, $dueText.$docsSection\n\n'
        'Detaliile bancare pentru transfer le regăsiți pe factura atașată. În cazul în care plata a fost deja efectuată, vă rugăm să ignorați această notificare.\n\n'
        'Vă mulțumim,\n'
        '_Echipa QualiAdept_';
  }

  /// Builds Option A polite receipt message in Romanian.
  static String buildReceiptShareMessage({
    required String studentName,
    required String programName,
    required double amount,
    required String currency,
    required int installmentNumber,
    required int totalInstallments,
    required String receiptNumber,
    String? receiptUrl,
    String? studentPhone,
  }) {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';
    final installmentText = totalInstallments > 1
        ? 'Rata $installmentNumber din $totalInstallments'
        : 'Plată Integrală';

    final pin = extractPinFromPhone(studentPhone);
    final pinNotice = (studentPhone != null && studentPhone.trim().isNotEmpty)
        ? '\n🔐 *PIN Securitate Document:* Ultimele 4 cifre ale numărului tău de telefon (*$pin*)'
        : '';

    final gatewayUrl = (receiptUrl != null && receiptUrl.trim().isNotEmpty)
        ? buildDocGatewayUrl(
            rawPdfUrl: receiptUrl,
            studentPhone: studentPhone,
            docTitle: 'Chitanță Plată $receiptNumber',
          )
        : null;

    final urlSection = gatewayUrl != null
        ? '\n\n📄 *Link Chitanță PDF:* $gatewayUrl$pinNotice'
        : '';

    return 'Salut *$studentName*! 👋\n\n'
        'Am înregistrat cu succes plata pentru *$installmentText* în valoare de *$amountFormatted* pentru programul *$programName*. 💳\n\n'
        'Aici ai chitanța confirmată și semnată de către noi (*$receiptNumber*).$urlSection\n\n'
        'Îți mulțumim și spor la învățat! 🚀\n'
        '_— QualiAdept_';
  }

  /// Launches WhatsApp with Option A pre-filled receipt delivery message.
  static Future<void> sendReceiptViaWhatsApp({
    required BuildContext context,
    required String? phone,
    required String studentName,
    required String programName,
    required double amount,
    required String currency,
    required int installmentNumber,
    required int totalInstallments,
    required String receiptNumber,
    String? receiptUrl,
  }) async {
    final rawPhone = phone?.trim() ?? '';
    final messageText = buildReceiptShareMessage(
      studentName: studentName,
      programName: programName,
      amount: amount,
      currency: currency,
      installmentNumber: installmentNumber,
      totalInstallments: totalInstallments,
      receiptNumber: receiptNumber,
      receiptUrl: receiptUrl,
      studentPhone: rawPhone,
    );

    if (rawPhone.isEmpty) {
      _showMissingPhoneDialog(context, messageText, (enteredPhone) async {
        await _launchWhatsApp(context, enteredPhone, messageText);
      });
      return;
    }

    final cleaned = cleanPhoneNumber(rawPhone);
    await _launchWhatsApp(context, cleaned, messageText);
  }

  /// Builds a friendly contract signature follow-up text in Romanian.
  static String buildContractFollowUpMessage({
    required String studentName,
    required String programName,
    required String createdDateStr,
    required String contractSigningUrl,
    String? studentPhone,
  }) {
    final pin = extractPinFromPhone(studentPhone);
    final pinNotice = (studentPhone != null && studentPhone.trim().isNotEmpty)
        ? '\n🔐 *PIN Securitate Document:* Ultimele 4 cifre ale numărului tău de telefon (*$pin*)'
        : '';

    return '🔔 *[QualiAdept Contract Follow-Up]*\n\n'
        'Buna *$studentName*,\n\n'
        'Îți reamintim că contractul de servicii pentru programul *$programName* a fost generat pe *$createdDateStr* și așteaptă semnătura ta.\n\n'
        '📝 *Link Semnare Contract:* ${contractSigningUrl.trim()}$pinNotice\n\n'
        'Te rugăm să accesezi linkul de mai sus pentru a revizui și semna contractul. Dacă ai întrebări, îmi poți scrie direct aici.\n\n'
        'O zi frumoasă,\n'
        '_Echipa QualiAdept_';
  }

  /// Launches WhatsApp with the pre-filled contract signature follow-up message.
  static Future<void> sendContractFollowUp({
    required BuildContext context,
    required String? phone,
    required String studentName,
    required String programName,
    required String createdDateStr,
    required String contractSigningUrl,
  }) async {
    final rawPhone = phone?.trim() ?? '';
    final messageText = buildContractFollowUpMessage(
      studentName: studentName,
      programName: programName,
      createdDateStr: createdDateStr,
      contractSigningUrl: contractSigningUrl,
      studentPhone: rawPhone,
    );

    if (rawPhone.isEmpty) {
      _showMissingPhoneDialog(context, messageText, (enteredPhone) async {
        await _launchWhatsApp(context, enteredPhone, messageText);
      });
      return;
    }

    final cleaned = cleanPhoneNumber(rawPhone);
    await _launchWhatsApp(context, cleaned, messageText);
  }

  /// Builds a polite prospect follow-up text in Romanian.
  static String buildProspectFollowUpMessage({
    required String prospectName,
    String? programName,
  }) {
    final progInfo = (programName != null && programName.isNotEmpty)
        ? ' privind discuția noastră despre programul *$programName*'
        : '';
    return 'Salut *$prospectName*! Revin cu un mesaj scurt$progInfo. Ai reușit să te gândești? Sunteți pregătit(ă) să facem pasul următor? Mulțumesc!';
  }

  /// Launches WhatsApp with the pre-filled prospect follow-up message.
  static Future<void> sendProspectFollowUp({
    required BuildContext context,
    required String? phone,
    required String prospectName,
    String? programName,
  }) async {
    final rawPhone = phone?.trim() ?? '';
    final messageText = buildProspectFollowUpMessage(
      prospectName: prospectName,
      programName: programName,
    );

    if (rawPhone.isEmpty) {
      _showMissingPhoneDialog(context, messageText, (enteredPhone) async {
        await _launchWhatsApp(context, enteredPhone, messageText);
      });
      return;
    }

    final cleaned = cleanPhoneNumber(rawPhone);
    await _launchWhatsApp(context, cleaned, messageText);
  }

  /// Launches WhatsApp with the pre-filled message, or prompts for phone number if missing.
  static Future<void> sendReminder({
    required BuildContext context,
    required String? phone,
    required String studentName,
    required String programName,
    required double amount,
    required String currency,
    required String dueDateStr,
    bool isDueTomorrow = false,
    String dueStage = 'overdue',
    int? daysUntilDue,
    String? invoiceUrl,
    String? invoiceNumber,
    String? contractPdfUrl,
  }) async {
    final rawPhone = phone?.trim() ?? '';
    final messageText = buildReminderMessage(
      studentName: studentName,
      programName: programName,
      amount: amount,
      currency: currency,
      dueDateStr: dueDateStr,
      isDueTomorrow: isDueTomorrow,
      dueStage: dueStage,
      daysUntilDue: daysUntilDue,
      invoiceUrl: invoiceUrl,
      invoiceNumber: invoiceNumber,
      contractPdfUrl: contractPdfUrl,
      studentPhone: rawPhone,
    );

    if (rawPhone.isEmpty) {
      _showMissingPhoneDialog(context, messageText, (enteredPhone) async {
        await _launchWhatsApp(context, enteredPhone, messageText);
      });
      return;
    }

    final cleaned = cleanPhoneNumber(rawPhone);
    await _launchWhatsApp(context, cleaned, messageText);
  }

  static Future<void> _launchWhatsApp(
    BuildContext context,
    String phone,
    String messageText,
  ) async {
    final encodedMessage = Uri.encodeComponent(messageText);
    final waUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    final webUrl = Uri.parse('https://web.whatsapp.com/send?phone=$phone&text=$encodedMessage');

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: messageText));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copied reminder message to clipboard! Open WhatsApp to send.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: messageText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp launch error. Message copied to clipboard!'),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      }
    }
  }

  static void _showMissingPhoneDialog(
    BuildContext context,
    String messageText,
    Function(String) onConfirmPhone,
  ) {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send WhatsApp Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No phone number recorded for this student. Please enter their phone number:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g. +40722571081)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: messageText));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder message copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Copy Message Only'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final entered = phoneController.text.trim();
                if (entered.isNotEmpty) {
                  Navigator.of(context).pop();
                  onConfirmPhone(cleanPhoneNumber(entered));
                }
              },
              child: const Text('Open WhatsApp'),
            ),
          ],
        );
      },
    );
  }
}
