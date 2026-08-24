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
    int? contractNumber,
  }) async {
    final subject = '✍️ Contract de Mentorat QualiAdept - Semnare Electronică';
    final currentYear = DateTime.now().year;
    final contractNumStr = contractNumber != null ? '#$contractNumber' : '';

    final htmlBody = '''
      <div style="font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 28px 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff; color: #1e293b;">
        <!-- Header -->
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
          <p style="color: #64748b; font-size: 13px; margin: 6px 0 0 0; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Semnare Contract Digital</p>
        </div>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />

        <!-- Salutation & Message -->
        <p style="font-size: 15px; line-height: 1.6; margin: 0 0 12px 0;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">Contractul tău de servicii pentru programul de mentorat a fost generat și semnat de mentor. Când ai un moment disponibil, te rugăm să accesezi portalul securizat pentru a revizui documentul și a aplica semnătura ta electronică:</p>

        <!-- Contract Details Box -->
        <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; margin: 20px 0;">
          <table style="width: 100%; border-collapse: collapse; font-size: 13.5px;">
            ${contractNumStr.isNotEmpty ? '<tr><td style="padding: 5px 0; color: #64748b; font-weight: 500;">Număr Contract:</td><td style="padding: 5px 0; font-weight: 600; color: #0f172a; text-align: right;">$contractNumStr</td></tr>' : ''}
            ${(programName != null && programName.isNotEmpty) ? '<tr><td style="padding: 5px 0; color: #64748b; font-weight: 500;">Program:</td><td style="padding: 5px 0; font-weight: 600; color: #0f172a; text-align: right;">$programName</td></tr>' : ''}
            <tr><td style="padding: 5px 0; color: #64748b; font-weight: 500;">Status Document:</td><td style="padding: 5px 0; font-weight: 600; color: #2563eb; text-align: right;">În așteptarea semnăturii tale</td></tr>
          </table>
        </div>

        <!-- Action Button -->
        <div style="text-align: center; margin: 28px 0;">
          <a href="$url" style="background-color: #1d4ed8; color: #ffffff; padding: 14px 32px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block; font-size: 15px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
            ✍️ Revizuiește și Semnează Contractul
          </a>
        </div>

        <!-- Direct Link Box -->
        <p style="font-size: 12.5px; color: #64748b; margin: 0 0 6px 0;">Sau accesează linkul direct în browser:</p>
        <div style="background-color: #f8fafc; padding: 10px 14px; border-radius: 6px; border: 1px solid #e2e8f0; word-break: break-all; font-size: 12px; color: #2563eb;">
          <a href="$url" style="color: #2563eb; text-decoration: none;">$url</a>
        </div>

        <p style="font-size: 13px; color: #64748b; line-height: 1.5; margin: 20px 0 0 0; font-style: italic;">Dacă ai orice întrebare legată de contract sau program, suntem cu drag la dispoziția ta.</p>

        <!-- Footer -->
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 16px 0;" />
        <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 0; line-height: 1.5;">
          DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear. Toate drepturile rezervate.<br/>
          Agreemint Realtime Notification System • QualiAdept Community
        </p>
      </div>
    ''';

    await _sendEmail(to: email, subject: subject, htmlBody: htmlBody);
  }

  /// Calculează și formatează exprimarea temporală relativă a scadenței în HTML (astăzi, mâine, în X zile, restantă).
  static String formatRelativeDueTextHtml(String dueDateStr, [DateTime? dueDateTime]) {
    DateTime? parsed = dueDateTime ?? DateTime.tryParse(dueDateStr);
    if (parsed == null) {
      return 'cu scadența pe data de <strong>$dueDateStr</strong>';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = targetDay.difference(today).inDays;

    if (diffDays == 0) {
      return 'cu scadența <strong>astăzi, $dueDateStr</strong>';
    } else if (diffDays == 1) {
      return 'cu scadența <strong>mâine, $dueDateStr</strong>';
    } else if (diffDays > 1) {
      return 'cu scadența în <strong>$diffDays zile</strong> (pe data de <strong>$dueDateStr</strong>)';
    } else if (diffDays == -1) {
      return 'care a înregistrat scadența <strong>ieri, $dueDateStr</strong> (restantă de 1 zi)';
    } else {
      final overdueDays = -diffDays;
      return 'care a depășit termenul de scadență cu <strong>$overdueDays zile</strong> (scadență inițială: <strong>$dueDateStr</strong>)';
    }
  }

  /// Trimite un memento de plată pentru o tranșă viitoare sau restantă prin email.
  Future<void> sendPaymentReminder({
    required String email,
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
    final subject = '💳 Memento Plată Tranșă - QualiAdept';
    final currentYear = DateTime.now().year;
    final relativeDueText = formatRelativeDueTextHtml(dueDate, dueDateTime);

    final hasContract = contractUrl != null && contractUrl.trim().isNotEmpty;
    final hasInvoice = invoiceUrl != null && invoiceUrl.trim().isNotEmpty;
    final hasDocs = hasContract || hasInvoice;

    final contractHtml = hasContract
        ? '''
        <div style="margin-bottom: 12px; padding: 14px 16px; background-color: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="vertical-align: middle;">
                <div style="font-size: 14px; font-weight: bold; color: #1e3a8a;">✍️ Contract Semnat & Termeni Agreați</div>
                <div style="font-size: 12px; color: #64748b; margin-top: 2px;">Consultă clauzele contractuale și graficul de plăți agreat</div>
              </td>
              <td style="text-align: right; vertical-align: middle; padding-left: 12px;">
                <a href="${contractUrl.trim()}" target="_blank" style="display: inline-block; background-color: #1e3a8a; color: #ffffff; text-decoration: none; padding: 8px 14px; border-radius: 6px; font-size: 12px; font-weight: bold; white-space: nowrap;">Vizualizează Contract ↗</a>
              </td>
            </tr>
          </table>
        </div>
        '''
        : '';

    final invoiceHtml = hasInvoice
        ? '''
        <div style="margin-bottom: 12px; padding: 14px 16px; background-color: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="vertical-align: middle;">
                <div style="font-size: 14px; font-weight: bold; color: #166534;">🧾 Factură Fiscală ${invoiceNumber != null && invoiceNumber.trim().isNotEmpty ? "(SOLO #$invoiceNumber)" : "(SOLO)"}</div>
                <div style="font-size: 12px; color: #15803d; margin-top: 2px;">Conține datele complete de facturare și contul bancar IBAN</div>
              </td>
              <td style="text-align: right; vertical-align: middle; padding-left: 12px;">
                <a href="${invoiceUrl.trim()}" target="_blank" style="display: inline-block; background-color: #16a34a; color: #ffffff; text-decoration: none; padding: 8px 14px; border-radius: 6px; font-size: 12px; font-weight: bold; white-space: nowrap;">Descarcă Factura ↗</a>
              </td>
            </tr>
          </table>
        </div>
        '''
        : '';

    final directLinksList = <String>[];
    if (hasContract) {
      directLinksList.add('• <strong>Contract:</strong> <a href="${contractUrl.trim()}" target="_blank" style="color: #1e3a8a;">${contractUrl.trim()}</a>');
    }
    if (hasInvoice) {
      directLinksList.add('• <strong>Factură:</strong> <a href="${invoiceUrl.trim()}" target="_blank" style="color: #16a34a;">${invoiceUrl.trim()}</a>');
    }

    final fallbackDirectLinksHtml = directLinksList.isNotEmpty
        ? '''
        <div style="background-color: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 6px; padding: 10px 14px; margin-top: 14px; font-size: 11px; color: #64748b; line-height: 1.6; word-break: break-all;">
          <strong>Linkuri directe pentru acces rapid:</strong><br/>
          ${directLinksList.join('<br/>')}
        </div>
        '''
        : '';

    final docsSection = hasDocs
        ? '''
        <!-- Document Links Section -->
        <div style="margin: 24px 0 16px 0;">
          <p style="font-size: 13px; font-weight: bold; color: #334155; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 0.5px;">📄 Documente & Detalii de Plată</p>
          $contractHtml
          $invoiceHtml
          $fallbackDirectLinksHtml
        </div>
        '''
        : '';

    final progText = (programName != null && programName.trim().isNotEmpty)
        ? ' pentru programul tău de mentorat (<strong>$programName</strong>)'
        : ' pentru programul tău de mentorat';

    final htmlBody = '''
      <div style="font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 28px 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff; color: #1e293b;">
        <!-- Header -->
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
          <p style="color: #d97706; font-size: 13px; margin: 6px 0 0 0; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Înștiințare Plată Tranșă</p>
        </div>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />

        <p style="font-size: 15px; line-height: 1.6; margin: 0 0 12px 0;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">Îți transmitem un memento prietenos referitor la următoarea tranșă de plată$progText, $relativeDueText:</p>

        <!-- Payment Details Card -->
        <div style="background-color: #fffbeb; border: 1px solid #fef3c7; border-radius: 8px; padding: 18px; margin: 20px 0;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr>
              <td style="padding: 6px 0; color: #92400e; font-weight: 500;">Sumă de Plată:</td>
              <td style="padding: 6px 0; font-weight: 800; font-size: 18px; color: #b45309; text-align: right;">${amount.toStringAsFixed(2)} $currency</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #92400e; font-weight: 500;">Dată Scadență:</td>
              <td style="padding: 6px 0; font-weight: 600; color: #78350f; text-align: right;">$dueDate</td>
            </tr>
          </table>
        </div>

        $docsSection

        <p style="font-size: 13px; color: #64748b; line-height: 1.5; margin: 20px 0 0 0;">Dacă ai nevoie de detalii suplimentare sau asistență, te rugăm să ne răspunzi direct la acest mesaj.</p>

        <!-- Footer -->
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 16px 0;" />
        <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 0; line-height: 1.5;">
          DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear. Toate drepturile rezervate.<br/>
          Agreemint Realtime Notification System • QualiAdept Community
        </p>
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
    String? receiptUrl,
  }) async {
    final subject = '🎉 Confirmare Plată Primită - QualiAdept';
    final currentYear = DateTime.now().year;

    final receiptSection = (receiptUrl != null && receiptUrl.trim().isNotEmpty)
        ? '''
        <div style="margin: 20px 0; text-align: center;">
          <a href="${receiptUrl.trim()}" target="_blank" style="display: inline-block; background-color: #16a34a; color: #ffffff; text-decoration: none; padding: 10px 20px; border-radius: 6px; font-size: 13px; font-weight: bold;">🧾 Descarcă Chitanța / Dovada Plății (PDF) ↗</a>
        </div>
        '''
        : '';

    final htmlBody = '''
      <div style="font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 28px 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff; color: #1e293b;">
        <!-- Header -->
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
          <p style="color: #16a34a; font-size: 13px; margin: 6px 0 0 0; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Confirmare Plată Înregistrată</p>
        </div>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />

        <p style="font-size: 15px; line-height: 1.6; margin: 0 0 12px 0;">Salut <strong>$name</strong>,</p>
        <p style="font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">Confirmăm cu succes înregistrarea plății tale pentru programul de mentorat. Îți mulțumim pentru promptitudine!</p>

        <!-- Receipt Box -->
        <div style="background-color: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 18px; margin: 20px 0;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr>
              <td style="padding: 6px 0; color: #166534; font-weight: 500;">Sumă Încasată:</td>
              <td style="padding: 6px 0; font-weight: 800; font-size: 18px; color: #15803d; text-align: right;">${amount.toStringAsFixed(2)} $currency</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #166534; font-weight: 500;">Status Tranzacție:</td>
              <td style="padding: 6px 0; font-weight: 600; color: #166534; text-align: right;">Confirmată ✅</td>
            </tr>
          </table>
        </div>

        $receiptSection

        <p style="font-size: 14px; line-height: 1.6; margin: 0;">Să avem o sesiune excelentă și mult succes în continuare! 🚀</p>

        <!-- Footer -->
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 16px 0;" />
        <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 0; line-height: 1.5;">
          DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear. Toate drepturile rezervate.<br/>
          Agreemint Realtime Notification System • QualiAdept Community
        </p>
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
    final currentYear = DateTime.now().year;
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final htmlContent = '''
      <div style="font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; padding: 28px 24px; color: #1e293b; max-width: 560px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <!-- Header -->
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
          <p style="color: #16a34a; font-size: 13px; margin: 6px 0 0 0; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Notificare Semnare Contract</p>
        </div>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />

        <p style="font-size: 15px; line-height: 1.6; margin: 0 0 16px 0;">Cursantul <strong>$studentName</strong> a finalizat semnarea electronică a contractului de mentorat.</p>

        <!-- Details Box -->
        <div style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; margin: 20px 0;">
          <table style="width: 100%; border-collapse: collapse; font-size: 13.5px;">
            <tr><td style="padding: 6px 0; color: #64748b; font-weight: 500;">Contract Nr.:</td><td style="padding: 6px 0; font-weight: 700; color: #0f172a; text-align: right;">#$contractNumber</td></tr>
            <tr><td style="padding: 6px 0; color: #64748b; font-weight: 500;">CNP / CUI Cursant:</td><td style="padding: 6px 0; font-weight: 600; color: #0f172a; text-align: right;">${studentCnp.isNotEmpty ? studentCnp : '-'}</td></tr>
            <tr><td style="padding: 6px 0; color: #64748b; font-weight: 500;">Program:</td><td style="padding: 6px 0; font-weight: 600; color: #0f172a; text-align: right;">$programName</td></tr>
            <tr><td style="padding: 6px 0; color: #64748b; font-weight: 500;">Dată Semnare:</td><td style="padding: 6px 0; font-weight: 600; color: #0f172a; text-align: right;">$dateStr</td></tr>
          </table>
        </div>

        <!-- Action Button -->
        <div style="text-align: center; margin: 28px 0;">
          <a href="$signedPdfUrl" style="background-color: #16a34a; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block; font-size: 15px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
            📄 Vizualizează Contractul PDF Semnat
          </a>
        </div>

        <!-- Footer -->
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 16px 0;" />
        <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 0; line-height: 1.5;">
          DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear. Toate drepturile rezervate.<br/>
          Agreemint Realtime Notification System • QualiAdept Community
        </p>
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
    final currentYear = DateTime.now().year;
    final htmlContent = '''
      <div style="font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, Helvetica, Arial, sans-serif; padding: 28px 24px; color: #1e293b; max-width: 560px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #1e3a8a; margin: 0; font-size: 22px; font-weight: bold; letter-spacing: 0.5px;">QualiAdept Mentorship</h2>
          <p style="color: #2563eb; font-size: 13px; margin: 6px 0 0 0; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;">Test Notificare Configurare</p>
        </div>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 24px;" />
        <p style="font-size: 15px; line-height: 1.6;">✅ <strong>Test Reușit!</strong> Notificările prin email pentru contracte semnate și linkuri de semnare sunt configurate activ și funcționează optim în Agreemint.</p>
        <p style="font-size: 12px; color: #64748b;">Trimis prin Resend la ${DateTime.now().toString().split('.')[0]}</p>
        <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0 16px 0;" />
        <p style="font-size: 11px; color: #94a3b8; text-align: center; margin: 0;">
          DATCU GEORGE-CRISTIAN PFA / QualiAdept © $currentYear.
        </p>
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
