import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  final String apiKey;

  const EmailService({required this.apiKey});

  /// Private helper sending transactional emails.
  /// 1. Uses Supabase RPC `send_resend_email` (100% immune to browser CORS restrictions on Web).
  /// 2. Falls back to direct HTTP REST API on mobile/desktop platforms.
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    final cleanEmail = to.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Adresa de email a destinatarului nu este validă: $to');
    }

    final key = apiKey.trim();

    // 1. Primary: Server-side dispatch via Supabase RPC (100% immune to browser CORS)
    try {
      final supabase = Supabase.instance.client;
      final rpcRes = await supabase.rpc(
        'send_resend_email',
        params: {
          'p_to': cleanEmail,
          'p_subject': subject,
          'p_html': htmlBody,
          if (key.isNotEmpty) 'p_api_key': key,
          'p_from': 'Mentoring <mentoring@qualiadept.eu>',
        },
      );

      if (rpcRes != null) {
        if (rpcRes is Map && rpcRes['success'] == false) {
          throw Exception(rpcRes['error'] ?? 'Eroare la trimiterea prin serverul Supabase.');
        }
        debugPrint('[EmailService] Email trimis cu succes prin Supabase RPC: $rpcRes');
        return;
      }
    } catch (rpcError) {
      debugPrint('[EmailService] Supabase RPC dispatch notice: $rpcError');
      if (kIsWeb) {
        // On Web, if RPC failed, we cannot do direct REST due to browser CORS
        throw Exception(
            'Nu s-a putut expedia emailul prin serverul Supabase. Verifică funcția SQL `send_resend_email` în Supabase SQL Editor. Detalii: $rpcError');
      }
    }

    // 2. Direct HTTP REST Fallback (Mobile/Desktop platforms)
    if (!kIsWeb) {
      if (key.isEmpty) {
        throw Exception(
            'Cheia API Resend lipsește. Configurează RESEND_API_KEY în Business Settings sau --dart-define.');
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
          throw Exception('Eroare Resend API (${response.statusCode}): $errorDetail');
        }
      } catch (e) {
        debugPrint('[EmailService] Failed to send email via direct REST API: $e');
        rethrow;
      }
    }
  }

  /// Trimite linkul de revizuire și semnare a contractului de mentorat prin email.
  Future<void> sendContractLink({
    required String email,
    required String name,
    required String url,
    String? programName,
  }) async {
    final subject = '✍️ Contract de Mentorat QualiAdept - Semnare Electronică';
    final progText = (programName != null && programName.isNotEmpty)
        ? ' pentru programul <strong>$programName</strong>'
        : '';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; color: #333;">
        <h2 style="color: #1565c0; margin-top: 0;">✍️ Contract Mentorat QualiAdept</h2>
        <p style="font-size: 15px;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 15px;">Contractul tău de servicii$progText a fost generat și semnat de mentor. Când ai un moment disponibil, te rugăm să accesezi linkul de mai jos pentru a revizui documentul și a aplica semnătura ta electronică:</p>
        <div style="text-align: center; margin: 25px 0;">
          <a href="$url" style="background-color: #1565c0; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 16px;">
            📄 Revizuiește și Semnează Contractul
          </a>
        </div>
        <p style="font-size: 13px; color: #666;">Sau deschide acest link direct în browser:<br/><a href="$url" style="color: #1565c0;">$url</a></p>
        <p style="font-size: 14px;">Dacă ai orice întrebare, suntem la dispoziția ta!</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept Community</p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  /// Trimite un memento de plată pentru o tranșă viitoare sau restantă prin email.
  Future<void> sendPaymentReminder({
    required String email,
    required String name,
    required double amount,
    required String dueDate,
    String currency = 'RON',
  }) async {
    final subject = '💳 Memento Plată Tranșă - QualiAdept';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; color: #333;">
        <h2 style="color: #e65100; margin-top: 0;">💳 Memento Plată Tranșă</h2>
        <p style="font-size: 15px;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 15px;">Îți transmitem un memento prietenos referitor la următoarea tranșă de plată pentru programul de mentorat:</p>
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0; background-color: #fafafa; border-radius: 6px; border: 1px solid #eee;">
          <tr>
            <td style="padding: 12px; color: #555; font-weight: bold;">Sumă de Plată:</td>
            <td style="padding: 12px; font-weight: bold; font-size: 16px; color: #e65100;">${amount.toStringAsFixed(2)} $currency</td>
          </tr>
          <tr>
            <td style="padding: 12px; color: #555; font-weight: bold;">Dată Scadență:</td>
            <td style="padding: 12px; font-weight: bold; color: #333;">$dueDate</td>
          </tr>
        </table>
        <p style="font-size: 14px;">Dacă ai nevoie de datele de facturare sau detalii suplimentare, te rugăm să ne răspunzi la acest mesaj.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept Community</p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  /// Trimite o confirmare de primire a plății prin email.
  Future<void> sendPaymentReceipt({
    required String email,
    required String name,
    required double amount,
    String currency = 'RON',
  }) async {
    final subject = '🎉 Confirmare Plată Primită - QualiAdept';
    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; color: #333;">
        <h2 style="color: #2e7d32; margin-top: 0;">🎉 Plată Înregistrată cu Succes!</h2>
        <p style="font-size: 15px;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 15px;">Confirmăm primirea plății tale în valoare de <strong>${amount.toStringAsFixed(2)} $currency</strong>. Îți mulțumim pentru promptitudine!</p>
        <p style="font-size: 15px;">Să avem o sesiune excelentă în continuare! 🚀</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;"/>
        <p style="font-size: 12px; color: #888; text-align: center;">Agreemint Realtime Notification System • QualiAdept Community</p>
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

    try {
      final service = EmailService(apiKey: apiKey ?? '');
      await service._sendEmail(to: cleanEmail, subject: subject, htmlBody: htmlContent);
      return true;
    } catch (e) {
      debugPrint('[EmailService] sendContractSignedEmailAlert error: $e');
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

    try {
      final service = EmailService(apiKey: apiKey ?? '');
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
