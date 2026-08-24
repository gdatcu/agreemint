import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final String apiKey;

  const EmailService({required this.apiKey});

  /// Private helper sending transactional emails via Resend HTTP REST API.
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    final cleanEmail = to.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Invalid recipient email address: $to');
    }

    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception(
          'Resend API key is not configured. Please set RESEND_API_KEY via --dart-define or Business Settings.');
    }

    final payload = {
      'from': 'Mentoring <mentoring@qualiadept.eu>',
      'to': [cleanEmail],
      'subject': subject,
      'html': htmlBody,
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorDetail = response.body;
        try {
          final resJson = jsonDecode(response.body);
          if (resJson is Map && resJson.containsKey('message')) {
            errorDetail = resJson['message'].toString();
          }
        } catch (_) {}
        throw Exception('Resend API Error (${response.statusCode}): $errorDetail');
      }
    } catch (e) {
      debugPrint('[EmailService] Failed to send email: $e');
      rethrow;
    }
  }

  /// Sends a contract review and signing link via email.
  Future<void> sendContractLink({
    required String email,
    required String name,
    required String url,
  }) async {
    final subject = 'Mentoring Agreement - Please Review & Sign';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1565c0; margin-top: 0;">✍️ Mentoring Agreement - Review & Sign</h2>
        <p style="font-size: 15px;">Hi <strong>$name</strong>,</p>
        <p style="font-size: 15px;">When you have a moment, please review and sign our mentoring agreement using the secure link below:</p>
        <div style="text-align: center; margin: 25px 0;">
          <a href="$url" style="background-color: #1565c0; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 16px;">
            📄 Review & Sign Agreement
          </a>
        </div>
        <p style="font-size: 13px; color: #666;">Or open this link in your browser:<br/><a href="$url" style="color: #1565c0;">$url</a></p>
        <p style="font-size: 14px;">Let me know if you have any questions!</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Mentorship • QualiAdept</p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  /// Sends an upcoming installment reminder via email.
  Future<void> sendPaymentReminder({
    required String email,
    required String name,
    required double amount,
    required String dueDate,
  }) async {
    final subject = 'Payment Reminder - Upcoming Installment';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #e65100; margin-top: 0;">💳 Upcoming Payment Reminder</h2>
        <p style="font-size: 15px;">Hi <strong>$name</strong>,</p>
        <p style="font-size: 15px;">Hope you're doing great! Just a quick reminder that your next installment is coming up soon.</p>
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0; background-color: #fafafa; border-radius: 6px; border: 1px solid #eee;">
          <tr>
            <td style="padding: 12px; color: #555; font-weight: bold;">Amount Due:</td>
            <td style="padding: 12px; font-weight: bold; font-size: 16px; color: #e65100;">${amount.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td style="padding: 12px; color: #555; font-weight: bold;">Due Date:</td>
            <td style="padding: 12px; font-weight: bold; color: #333;">$dueDate</td>
          </tr>
        </table>
        <p style="font-size: 14px;">Let me know if you need the payment details or invoice again!</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Mentorship • QualiAdept</p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  /// Sends a payment receipt confirmation via email.
  Future<void> sendPaymentReceipt({
    required String email,
    required String name,
    required double amount,
  }) async {
    final subject = 'Payment Confirmation Receipt';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #2e7d32; margin-top: 0;">🎉 Payment Received</h2>
        <p style="font-size: 15px;">Hi <strong>$name</strong>,</p>
        <p style="font-size: 15px;">Just confirming I received your payment of <strong>${amount.toStringAsFixed(2)}</strong>.</p>
        <p style="font-size: 15px;">Thank you! Let's crush our next session.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Mentorship • QualiAdept</p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  // --- Static Helpers for Backwards Compatibility ---

  /// Sends a secure 6-digit OTP verification email via Supabase Postgres RPC.
  static Future<bool> sendOtpEmail({
    required String email,
    required String otp,
    required String studentName,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc(
        'send_email_otp',
        params: {
          'p_email': email.trim().toLowerCase(),
          'p_otp': otp.trim(),
          'p_name': studentName.trim(),
        },
      );

      if (response != null && response is Map) {
        final int? status = response['status'] as int?;
        return status == 200 || status == 201;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends an email notification alert when a contract is signed by a student.
  static Future<bool> sendContractSignedEmailAlert({
    required String mentorEmail,
    required String studentName,
    required String studentCnp,
    required String programName,
    required int contractNumber,
    required String signedPdfUrl,
    String? resendApiKey,
  }) async {
    final cleanEmail = mentorEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) return false;

    final apiKey = resendApiKey?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final subject = '✍️ Contract Semnat de $studentName (Contract #$contractNumber)';
        final htmlContent = '''
            <div style="font-family: Arial, sans-serif; padding: 20px; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px;">
              <h2 style="color: #2e7d32; margin-top: 0;">🎉 Contract Semnat cu Succes!</h2>
              <p style="font-size: 15px;">Cursantul <strong>$studentName</strong> a semnat contractul de mentorat.</p>
              <table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
                <tr><td style="padding: 6px 0; color: #666;"><strong>Contract Nr.:</strong></td><td>#$contractNumber</td></tr>
                <tr><td style="padding: 6px 0; color: #666;"><strong>CNP / CUI:</strong></td><td>${studentCnp.isNotEmpty ? studentCnp : '-'}</td></tr>
                <tr><td style="padding: 6px 0; color: #666;"><strong>Program:</strong></td><td>$programName</td></tr>
                <tr><td style="padding: 6px 0; color: #666;"><strong>Dată Semnare:</strong></td><td>${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}</td></tr>
              </table>
              <br/>
              <a href="$signedPdfUrl" style="background-color: #2e7d32; color: white; padding: 12px 20px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">
                📄 Vizualizează Contractul PDF Semnat
              </a>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
              <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept</p>
            </div>
          ''';

        final service = EmailService(apiKey: apiKey);
        await service._sendEmail(to: cleanEmail, subject: subject, htmlBody: htmlContent);
        return true;
      } catch (e) {
        debugPrint('[EmailService] sendContractSignedEmailAlert error: $e');
      }
    }
    return false;
  }

  /// Sends a test email notification to verify mentor email configuration.
  static Future<Map<String, dynamic>> sendTestEmailAlert({
    required String mentorEmail,
    String? resendApiKey,
  }) async {
    final cleanEmail = mentorEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'message': 'Te rugăm să introduci o adresă de email validă.'};
    }

    final apiKey = resendApiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      return {
        'success': false,
        'message': '❌ Resend API Key lipsește. Configurează cheia în setări.'
      };
    }

    final htmlContent = '''
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2 style="color: #1565c0;">✅ Test Notificare Email Reușit!</h2>
        <p>Notificările prin email pentru contracte semnate sunt configurate activ în Agreemint.</p>
        <p style="font-size: 12px; color: #777;">Trimis prin Resend la ora ${DateTime.now().toString()}</p>
      </div>
    ''';

    try {
      final service = EmailService(apiKey: apiKey);
      await service._sendEmail(
        to: cleanEmail,
        subject: '✅ Test Notificare Email Agreemint',
        htmlBody: htmlContent,
      );
      return {
        'success': true,
        'message': '🎉 Email de test expediat cu succes prin Resend la $cleanEmail!'
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Eroare trimitere email: $e'
      };
    }
  }
}
