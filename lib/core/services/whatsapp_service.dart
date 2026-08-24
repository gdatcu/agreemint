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
      throw Exception('Phone number cannot be empty.');
    }

    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('whatsapp://send?phone=$cleanedPhone&text=$encodedMessage');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch WhatsApp URL: $uri');
      }
    }
  }

  /// Sends the contract review & signing link.
  static Future<void> sendContractLink({
    required String phone,
    required String name,
    required String url,
  }) async {
    final message =
        "Hi $name! 👋 When you have a moment, please review and sign our mentoring agreement here: $url. Let me know if you have questions!";
    await _launch(phone, message);
  }

  /// Sends an upcoming installment reminder.
  static Future<void> sendPaymentReminder({
    required String phone,
    required String name,
    required double amount,
    required String dueDate,
  }) async {
    final message =
        "Hi $name! Hope you're doing great. Just a quick reminder that the next installment of $amount is coming up on $dueDate. Let me know if you need the payment details again!";
    await _launch(phone, message);
  }

  /// Sends a payment received confirmation receipt.
  static Future<void> sendPaymentReceipt({
    required String phone,
    required String name,
    required double amount,
  }) async {
    final message =
        "Hi $name! Just confirming I received your payment of $amount. Thank you! Let's crush our next session.";
    await _launch(phone, message);
  }

  /// Sends a general follow-up message to enrolled students.
  static Future<void> sendGeneralFollowUp({
    required String phone,
    required String name,
  }) async {
    final message =
        "Hi $name! 👋 Just checking in to see how things are going with the program. Let me know if you need anything!";
    await _launch(phone, message);
  }
}
