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

  /// Builds an objective, formal payment notification in Romanian from QualiAdept Billing Bot.
  static String buildReminderMessage({
    required String studentName,
    required String programName,
    required double amount,
    required String currency,
    required String dueDateStr,
    bool isDueTomorrow = false,
    String dueStage = 'overdue',
  }) {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';

    if (isDueTomorrow || dueStage == 'tomorrow') {
      return '🤖 *[Notificare Automată - QualiAdept Billing]*\n\n'
          'Stimate/ă *$studentName*,\n\n'
          'Vă reamintim amabil că pentru înregistrarea la programul *$programName*, tranșa în valoare de *$amountFormatted* are termenul de plată *mâine, $dueDateStr*.\n\n'
          'Vă rugăm să efectuați transferul bancar conform acordului agreat. Dacă ați efectuat deja plata, vă rugăm să ignorați această notificare automatizată.\n\n'
          '_Sistemul Automat de Facturare QualiAdept._';
    }

    if (dueStage == 'today') {
      return '🤖 *[Notificare Automată - QualiAdept Billing]*\n\n'
          'Stimate/ă *$studentName*,\n\n'
          'Vă reamintim amabil că pentru înregistrarea la programul *$programName*, tranșa în valoare de *$amountFormatted* are termenul de plată *astăzi, $dueDateStr*.\n\n'
          'Vă rugăm să efectuați transferul bancar conform acordului agreat. Dacă ați efectuat deja plata, vă rugăm să ignorați această notificare automatizată.\n\n'
          '_Sistemul Automat de Facturare QualiAdept._';
    }

    return '🤖 *[Notificare Automată - QualiAdept Billing]*\n\n'
        'Stimate/ă *$studentName*,\n\n'
        'Vă informăm că pentru înregistrarea la programul *$programName*, tranșa în valoare de *$amountFormatted* a înregistrat termenul de plată pe data de *$dueDateStr*.\n\n'
        'Vă rugăm să efectuați transferul bancar conform acordului agreat. Dacă ați efectuat deja plata, vă rugăm să ignorați această notificare automatizată.\n\n'
        '_Sistemul Automat de Facturare QualiAdept._';
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
