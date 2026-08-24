import 'package:url_launcher/url_launcher.dart';

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

  /// Trimite o notificare / memento de plată pentru o tranșă.
  static Future<void> sendPaymentReminder({
    required String phone,
    required String name,
    required double amount,
    required String dueDate,
    String currency = 'RON',
  }) async {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';
    final message = '\u{1F4B3} *[QualiAdept Notificare Plată]*\n\n'
        'Salut *$name*,\n\n'
        'Îți transmitem un memento prietenos referitor la următoarea tranșă de plată în valoare de *$amountFormatted*, cu scadența pe data de *$dueDate*.\n\n'
        'Dacă ai nevoie de detalii de plată sau factură, dă-ne un semn!\n\n'
        'Mulțumim,\n'
        '_Echipa QualiAdept_';
    await _launch(phone, message);
  }

  /// Trimite o confirmare de primire a plății.
  static Future<void> sendPaymentReceipt({
    required String phone,
    required String name,
    required double amount,
    String currency = 'RON',
  }) async {
    final amountFormatted = '${amount.toStringAsFixed(2)} $currency';
    final message = '\u{1F389} *[QualiAdept Confirmare Plată]*\n\n'
        'Salut *$name*,\n\n'
        'Confirmăm primirea plății tale în valoare de *$amountFormatted*. Îți mulțumim pentru promptitudine!\n\n'
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
