import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
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

    // 1. Dispatch via Resend REST API if Resend API key is configured
    final apiKey = resendApiKey?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final payload = {
          'from': 'Agreemint Alerts <onboarding@resend.dev>',
          'to': [cleanEmail],
          'subject': '✍️ Contract Semnat de $studentName (Contract #$contractNumber)',
          'html': '''
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
              <br/><br/>
              <hr style="border: none; border-top: 1px solid #eee;"/>
              <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept</p>
            </div>
          ''',
        };

        debugPrint('[EmailService] Sending contract signed alert via Resend to $cleanEmail...');
        final response = await http.post(
          Uri.parse('https://api.resend.com/emails'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('[EmailService] Resend email delivered successfully: ${response.body}');
          return true;
        }
        debugPrint('[EmailService] Resend API Error: ${response.statusCode} - ${response.body}');
      } catch (e) {
        debugPrint('[EmailService] Failed to send email via Resend API: $e');
      }
    }

    // 2. Fallback to Supabase RPC send_email_notification
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc(
        'send_email_notification',
        params: {
          'p_email': cleanEmail,
          'p_subject': '✍️ Contract Semnat: $studentName (Contract #$contractNumber)',
          'p_body': 'Contractul #$contractNumber a fost semnat de $studentName. Vezi PDF: $signedPdfUrl',
        },
      );
      return response != null;
    } catch (_) {
      return false;
    }
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

    // 1. If Resend API Key is set, send via Resend
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final payload = {
          'from': 'Agreemint Alerts <onboarding@resend.dev>',
          'to': [cleanEmail],
          'subject': '✅ Test Notificare Email Agreemint',
          'html': '''
            <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
              <h2 style="color: #1565c0;">✅ Test Notificare Email Reușit!</h2>
              <p>Notificările prin email pentru contracte semnate sunt configurate activ în Agreemint.</p>
              <p style="font-size: 12px; color: #777;">Trimis prin Resend API la ora ${DateTime.now().toString()}</p>
            </div>
          ''',
        };

        debugPrint('[EmailService] Sending test email via Resend to $cleanEmail...');
        final response = await http.post(
          Uri.parse('https://api.resend.com/emails'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('[EmailService] Test email delivered successfully: ${response.body}');
          return {'success': true, 'message': '🎉 Email de test trimis cu succes prin Resend la $cleanEmail!'};
        } else {
          final resJson = jsonDecode(response.body);
          final errorMsg = resJson['message'] ?? response.body;
          debugPrint('[EmailService] Resend test error: ${response.statusCode} - $errorMsg');
          return {
            'success': false,
            'message': '❌ Eroare Resend (${response.statusCode}): $errorMsg'
          };
        }
      } catch (e) {
        debugPrint('[EmailService] Resend connection error: $e');
        return {'success': false, 'message': '❌ Eroare conexiune Resend: $e'};
      }
    }

    // 2. If no Resend API key, try Supabase RPC or notify missing key
    try {
      final supabase = Supabase.instance.client;
      await supabase.rpc(
        'send_email_notification',
        params: {
          'p_email': cleanEmail,
          'p_subject': '✅ Test Notificare Email Agreemint',
          'p_body': 'Notificările prin email pentru contracte semnate sunt configurate activ!',
        },
      );
      return {'success': true, 'message': '🎉 Notificare de test expediată către $cleanEmail!'};
    } catch (_) {
      return {
        'success': false,
        'message': '💡 Pentru trimiterea de emailuri pe telefon, obține o cheie gratuită pe Resend.com (100% gratuit) și lipește-o în câmpul "Cheie API Resend".'
      };
    }
  }
}
