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
              <br/><br/>
              <hr style="border: none; border-top: 1px solid #eee;"/>
              <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept</p>
            </div>
          ''';

        // 1. Primary: Server-side dispatch via Supabase RPC (100% immune to browser CORS)
        try {
          final supabase = Supabase.instance.client;
          final rpcRes = await supabase.rpc(
            'send_resend_email',
            params: {
              'p_to': cleanEmail,
              'p_subject': subject,
              'p_html': htmlContent,
              'p_api_key': apiKey,
            },
          );
          if (rpcRes != null && (rpcRes['success'] == true || rpcRes is Map)) {
            debugPrint('[EmailService] Contract signed email dispatched via Supabase RPC: $rpcRes');
            return true;
          }
        } catch (e) {
          debugPrint('[EmailService] Supabase send_resend_email RPC notice: $e');
        }

        // 2. Direct REST Fallback (for mobile/desktop platforms without browser CORS)
        if (!kIsWeb) {
          final payload = {
            'from': 'Agreemint Alerts <onboarding@resend.dev>',
            'to': [cleanEmail],
            'subject': subject,
            'html': htmlContent,
          };
          debugPrint('[EmailService] Sending contract signed alert via direct Resend API to $cleanEmail...');
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
        }
      } catch (e) {
        debugPrint('[EmailService] Failed to send email via Resend API: $e');
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
    final htmlContent = '''
      <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
        <h2 style="color: #1565c0;">✅ Test Notificare Email Reușit!</h2>
        <p>Notificările prin email pentru contracte semnate sunt configurate activ în Agreemint.</p>
        <p style="font-size: 12px; color: #777;">Trimis prin Resend la ora ${DateTime.now().toString()}</p>
      </div>
    ''';

    // 1. Primary: Server-side dispatch via Supabase RPC (immune to browser CORS)
    try {
      final supabase = Supabase.instance.client;
      final rpcRes = await supabase.rpc(
        'send_resend_email',
        params: {
          'p_to': cleanEmail,
          'p_subject': '✅ Test Notificare Email Agreemint',
          'p_html': htmlContent,
          if (apiKey != null && apiKey.isNotEmpty) 'p_api_key': apiKey,
        },
      );
      if (rpcRes != null && (rpcRes['success'] == true || rpcRes is Map)) {
        debugPrint('[EmailService] Test email dispatched via Supabase RPC: $rpcRes');
        return {
          'success': true,
          'message': '🎉 Email de test expediat cu succes prin Resend la $cleanEmail!'
        };
      }
    } catch (e) {
      debugPrint('[EmailService] Supabase send_resend_email RPC notice: $e');
    }

    // 2. Direct REST Fallback (for mobile/desktop platforms)
    if (apiKey != null && apiKey.isNotEmpty && !kIsWeb) {
      try {
        final payload = {
          'from': 'Agreemint Alerts <onboarding@resend.dev>',
          'to': [cleanEmail],
          'subject': '✅ Test Notificare Email Agreemint',
          'html': htmlContent,
        };

        debugPrint('[EmailService] Sending test email via direct Resend API to $cleanEmail...');
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

    return {
      'success': false,
      'message': '❌ Pentru activare, rulează scriptul SQL în Supabase Dashboard > SQL Editor.'
    };
  }
}
