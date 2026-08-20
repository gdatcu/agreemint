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
}
