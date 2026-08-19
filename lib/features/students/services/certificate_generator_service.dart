import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateGeneratorService {
  /// Generates a landscape A4 Bilingual (RO/EN) Mentorship Completion Certificate PDF.
  Future<Uint8List> generateCertificatePdf({
    required String studentName,
    required String programName,
    required DateTime completionDate,
    int courseHours = 50,
    int sessionCount = 20,
    String sessionDuration = '2.5',
    String? certificateId,
    String mentorName = 'DATCU GEORGE-CRISTIAN',
    String companyName = 'QUALIADEPT',
    Uint8List? mentorSignatureBytes,
  }) async {
    pw.Font baseFont = pw.Font.helvetica();
    pw.Font boldFont = pw.Font.helveticaBold();
    pw.Font italicFont = pw.Font.helveticaOblique();

    try {
      baseFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (_) {
      // Standard Helvetica fallback
    }

    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
      fontFallback: [baseFont],
    );

    final pdf = pw.Document(theme: theme);

    // Load QualiAdept logo if present
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/qualiAdept_logo_1.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? signatureImage;
    if (mentorSignatureBytes != null && mentorSignatureBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(mentorSignatureBytes);
    }

    final certCode = certificateId ??
        'CERT-${completionDate.year}-${completionDate.millisecondsSinceEpoch.toString().substring(7)}';

    final formattedDate =
        '${completionDate.day.toString().padLeft(2, '0')}.${completionDate.month.toString().padLeft(2, '0')}.${completionDate.year}';

    final navyColor = PdfColor.fromHex('#0F172A');
    final goldColor = PdfColor.fromHex('#D97706');
    final darkGold = PdfColor.fromHex('#B45309');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: goldColor, width: 3),
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColors.white,
            ),
            child: pw.Container(
              margin: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: navyColor, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (logoImage != null)
                        pw.Image(logoImage, height: 44)
                      else
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: goldColor,
                          ),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'ID: $certCode',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'Data / Date: $formattedDate',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 12),

                  // Main Certificate Title
                  pw.Text(
                    'CERTIFICAT DE ABSOLVIRE',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: navyColor,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.Text(
                    'CERTIFICATE OF COMPLETION',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: goldColor,
                      letterSpacing: 3,
                    ),
                  ),

                  pw.SizedBox(height: 16),

                  // Subtitle
                  pw.Text(
                    'Se acordă prin prezenta lui / This is proudly presented to',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  // Student Name (Highlight Accent)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 24, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: goldColor, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      studentName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // Completion Description
                  pw.Text(
                    'pentru absolvirea cu succes a programului intensiv de mentorat și pregătire practică:',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    'for successfully completing the intensive mentorship program:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  // Program Name Badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#CBD5E1'), width: 1),
                    ),
                    child: pw.Text(
                      programName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 6),

                  pw.Column(
                    children: [
                      pw.Text(
                        'Durată totală: $courseHours ore ($sessionCount sesiuni x ${sessionDuration}h) de consultanță live și practică aplicată',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Total duration: $courseHours hours ($sessionCount sessions x ${sessionDuration}h) of live mentorship and hands-on practice',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // Bottom Signatures & Verification Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // QR Code Verification
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.BarcodeWidget(
                            data:
                                'https://apps.qualiadept.eu/agreemint/#/verify-cert?id=$certCode&name=${Uri.encodeComponent(studentName)}&prog=${Uri.encodeComponent(programName)}&date=$formattedDate&hours=$courseHours',
                            barcode: pw.Barcode.qrCode(),
                            width: 50,
                            height: 50,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Scan to verify authenticity',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),

                      // Seal / Badge Icon text
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 48,
                            height: 48,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: goldColor, width: 2),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'SEAL\nVERIFIED',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                  color: goldColor,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'OFFICIAL VERIFIED',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                        ],
                      ),

                      // Mentor Signature Box
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            height: 40,
                            width: 140,
                            child: signatureImage != null
                                ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                                : pw.Center(
                                    child: pw.Text(
                                      'Datcu George-Cristian',
                                      style: pw.TextStyle(
                                        fontSize: 11,
                                        fontStyle: pw.FontStyle.italic,
                                        fontWeight: pw.FontWeight.bold,
                                        color: navyColor,
                                      ),
                                    ),
                                  ),
                          ),
                          pw.Container(
                            width: 150,
                            child: pw.Divider(color: navyColor, thickness: 1),
                          ),
                          pw.Text(
                            mentorName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: navyColor,
                            ),
                          ),
                          pw.Text(
                            'Lead Mentor & Provider / QUALIADEPT',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
