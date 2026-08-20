import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: 'RESEND_API_KEY_PLACEHOLDER',
  );
  static const String _resendEndpoint = 'https://api.resend.com/emails';

  /// Sends a secure 6-digit OTP verification email to the client using Resend.
  static Future<bool> sendOtpEmail({
    required String email,
    required String otp,
    required String studentName,
  }) async {
    try {
      final currentYear = DateTime.now().year;

      final body = {
        'from': 'QualiAdept <billing@qualiadept.eu>',
        'to': [email.trim().toLowerCase()],
        'subject': 'Cod de securitate QualiAdept / Verification Code',
        'html': '''
<div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 550px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff; color: #1e293b;">
  <div style="text-align: center; margin-bottom: 24px;">
    <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
    <p style="color: #64748b; font-size: 13px; margin: 6px 0 0 0; font-weight: 500; text-transform: uppercase; letter-spacing: 1px;">Secured Contract Verification</p>
  </div>
  <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />
  <p style="font-size: 15px; line-height: 1.6; margin: 0 0 12px 0;">Salut <strong>$studentName</strong>,</p>
  <p style="font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">Îți mulțumim pentru înscrierea în programul de mentorat QualiAdept! Pentru a accesa, revizui și semna contractul tău digital de colaborare, folosește codul de securitate OTP de mai jos:</p>
  
  <div style="background-color: #f8fafc; padding: 18px; text-align: center; border-radius: 8px; margin: 24px 0; border: 1px dashed #cbd5e1;">
    <span style="font-size: 28px; font-weight: 800; letter-spacing: 6px; color: #0f172a; font-family: monospace;">$otp</span>
  </div>
  
  <p style="font-size: 12.5px; color: #64748b; line-height: 1.5; margin: 20px 0 0 0; font-style: italic;">Acest cod este confidențial și valid pentru sesiunea curentă. Dacă nu ai solicitat inițierea semnării acestui contract, te rugăm să ignori acest mesaj.</p>
  
  <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 0 0;" />
  <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 16px 0 0 0;">DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear. Toate drepturile rezervate.</p>
</div>
'''
      };

      final response = await http.post(
        Uri.parse(_resendEndpoint),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
