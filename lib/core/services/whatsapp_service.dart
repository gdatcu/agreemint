import 'package:url_launcher/url_launcher.dart';
import 'whatsapp_reminder_service.dart';

class WhatsAppService {
  /// Cleans the phone string:
  /// - Removes spaces, dashes, plus signs, and other non-digit characters.
  /// - If the number starts with '07' and has 10 digits (Romanian format), prepends '40'.
  /// - If it starts with '40', leaves it as is.
  static String cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('07') && cleaned.length == 10) {
      cleaned = '40${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Base launcher for WhatsApp deep links.
  static Future<void> _launch(String phone, String message) async {
    final cleanedPhone = cleanPhoneNumber(phone);
    if (cleanedPhone.isEmpty) {
      throw Exception('Numărul de telefon nu este completat.');
    }

    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('whatsapp://send?phone=$cleanedPhone&text=$encodedMessage');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Nu s-a putut deschide aplicația WhatsApp pentru: $uri');
      }
    }
  }

  /// Trimite linkul de revizuire și semnare a contractului de mentorat.
  static Future<void> sendContractLink({
    required String phone,
    required String name,
    required String url,
    String? programName,
  }) async {
    final progText = (programName != null && programName.isNotEmpty)
        ? ' pentru programul *$programName*'
        : '';
    final message = '\u{1F4DD} *[QualiAdept Contract Mentorat]*\n\n'
        'Salut *$name*,\n\n'
        'Contractul de servicii$progText a fost generat și semnat de mentor.\n\n'
        '\u{270D}\u{FE0F} *Link Semnare Contract:* $url\n\n'
        'Te rugăm să accesezi linkul de mai sus pentru a revizui și aplica semnătura ta electronică.\n\n'
        'Mulțumim,\n'
        '_Echipa QualiAdept_';
    await _launch(phone, message);
  }

  /// Calculează și formatează exprimarea temporală relativă a scadenței (astăzi, mâine, în X zile, restantă).
  static String formatRelativeDueText(String dueDateStr, [DateTime? dueDateTime]) {
    DateTime? parsed = dueDateTime ?? DateTime.tryParse(dueDateStr);
    if (parsed == null) {
      return 'cu scadența pe data de *$dueDateStr*';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = targetDay.difference(today).inDays;

    if (diffDays == 0) {
      return 'cu scadența *astăzi, $dueDateStr*';
    } else if (diffDays == 1) {
      return 'cu scadența *mâine, $dueDateStr*';
    } else if (diffDays > 1) {
      return 'cu scadența în *$diffDays zile* (pe data de *$dueDateStr*)';
    } else if (diffDays == -1) {
      return 'care a înregistrat scadența *ieri, $dueDateStr* (restantă de 1 zi)';
    } else {
      final overdueDays = -diffDays;
      return 'care a depășit termenul de scadență cu *$overdueDays zile* (scadență: *$dueDateStr*)';
    }
  }

  /// Construiește mesajul text de notificare / memento de plată pentru WhatsApp.
  static String buildPaymentReminderMessage({
    required String name,
    required double amount,
    required String dueDate,
    String currency = 'RON',
    String? contractUrl,
    String? invoiceUrl,
    String? invoiceNumber,
    String? programName,
    String? studentPhone,
    DateTime? dueDateTime,
  }) {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';
    final dueText = formatRelativeDueText(dueDate, dueDateTime);
    final pin = WhatsAppReminderService.extractPinFromPhone(studentPhone);

    final isPortalLink = contractUrl != null && contractUrl.contains('/sign/');

    String docsSection;
    if (isPortalLink) {
      docsSection = '\n\n\u{1F510} *Portal Securizat Documente (Contract & Factură):*\n'
          '${contractUrl.trim()}\n\n'
          '\u{1F6E1}\u{FE0F} *Instrucțiuni de Acces Securizat:*\n'
          'La deschidere, introduceți adresa dvs. de email, ultimele 4 cifre ale nr. de telefon (*$pin*) și codul OTP primit pe email.';
    } else {
      final docsList = <String>[];
      if (contractUrl != null && contractUrl.trim().isNotEmpty) {
        docsList.add('• \u{270D}\u{FE0F} *Contract Semnat:* ${contractUrl.trim()}');
      }
      if (invoiceUrl != null && invoiceUrl.trim().isNotEmpty) {
        final invNumText = (invoiceNumber != null && invoiceNumber.trim().isNotEmpty)
            ? ' (SOLO #$invoiceNumber)'
            : ' (SOLO)';
        docsList.add('• \u{1F9FE} *Factură Fiscală$invNumText:* ${invoiceUrl.trim()}');
      }
      if (docsList.isNotEmpty) {
        docsList.add('🔐 *PIN Securitate:* Ultimele 4 cifre ale numărului de telefon (*$pin*)');
        docsSection = '\n\n\u{1F4C4} *Documente Securizate & Detalii de Plată:*\n${docsList.join('\n')}';
      } else {
        docsSection = '';
      }
    }

    final progText = (programName != null && programName.trim().isNotEmpty)
        ? ' pentru programul de mentorat *$programName*'
        : '';

    return '\u{1F4B3} *[QualiAdept Notificare Plată]*\n\n'
        'Salut *$name*,\n\n'
        'Îți transmitem un memento prietenos referitor la următoarea tranșă de plată$progText în valoare de *$amountFormatted*, $dueText.$docsSection\n\n'
        'Dacă ai nevoie de detalii suplimentare sau asistență, dă-ne un semn!\n\n'
        'Mulțumim,\n'
        '_Echipa QualiAdept_';
  }

  /// Trimite o notificare / memento de plată pentru o tranșă pe WhatsApp.
  static Future<void> sendPaymentReminder({
    required String phone,
    required String name,
    required double amount,
    required String dueDate,
    String currency = 'RON',
    String? contractUrl,
    String? invoiceUrl,
    String? invoiceNumber,
    String? programName,
    DateTime? dueDateTime,
  }) async {
    final message = buildPaymentReminderMessage(
      name: name,
      amount: amount,
      dueDate: dueDate,
      currency: currency,
      contractUrl: contractUrl,
      invoiceUrl: invoiceUrl,
      invoiceNumber: invoiceNumber,
      programName: programName,
      studentPhone: phone,
      dueDateTime: dueDateTime,
    );
    await _launch(phone, message);
  }

  /// Trimite o confirmare de primire a plății.
  static Future<void> sendPaymentReceipt({
    required String phone,
    required String name,
    required double amount,
    String currency = 'RON',
    String? receiptUrl,
  }) async {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';
    final receiptSection = (receiptUrl != null && receiptUrl.trim().isNotEmpty)
        ? '\n\n\u{1F9FE} *Chitanță / Dovadă Plată:* ${receiptUrl.trim()}'
        : '';

    final message = '\u{1F389} *[QualiAdept Confirmare Plată]*\n\n'
        'Salut *$name*,\n\n'
        'Confirmăm primirea plății tale în valoare de *$amountFormatted*. Îți mulțumim pentru promptitudine!$receiptSection\n\n'
        'Să avem o sesiune excelentă în continuare! \u{1F680}\n\n'
        'Cu drag,\n'
        '_Echipa QualiAdept_';
    await _launch(phone, message);
  }

  /// Trimite un mesaj de follow-up / check-in pentru un cursant.
  static Future<void> sendGeneralFollowUp({
    required String phone,
    required String name,
  }) async {
    final message = '\u{1F44B} *[QualiAdept Check-in]*\n\n'
        'Salut *$name*,\n\n'
        'Îți dăm un scurt mesaj de verificare să vedem cum decurg lucrurile în programul de mentorat și dacă te putem ajuta cu ceva în această etapă.\n\n'
        'Spor și o zi excelentă! \u{1F680}\n\n'
        'Cu drag,\n'
        '_Echipa QualiAdept_';
    await _launch(phone, message);
  }
}
