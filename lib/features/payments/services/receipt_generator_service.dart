import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptGeneratorService {
  /// Generates a bilingual (RO/EN) Official Payment Receipt PDF document.
  Future<Uint8List> generateReceiptPdf({
    required String receiptNumber,
    required DateTime paymentDate,
    required String studentName,
    required String studentEmail,
    required String programName,
    required int installmentNumber,
    required int totalInstallments,
    required double amountPaid,
    String currency = 'EUR',
    String paymentMethod = 'Bank Transfer',
    String? transactionReference,
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
      // Fallback to standard Helvetica if Google Fonts cannot be downloaded offline
    }

    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
      fontFallback: [baseFont],
    );

    final pdf = pw.Document(theme: theme);

    // Load QualiAdept header logo if present
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/qualiAdept_logo_1.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? signatureImage;
    if (mentorSignatureBytes != null && mentorSignatureBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(mentorSignatureBytes);
    }

    final formattedDate =
        '${paymentDate.day.toString().padLeft(2, '0')}.${paymentDate.month.toString().padLeft(2, '0')}.${paymentDate.year}';
    final formattedAmount = '${amountPaid.toStringAsFixed(2)} $currency';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row with Logo & Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Image(logoImage, height: 45)
                      else
                        pw.Text(
                          'QualiAdept',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                        ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'QualiAdept Mentorship Platform',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Bucuresti, Romania | CIF: RO123456',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'CHITANTA / RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Nr. / No: $receiptNumber',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        'Data / Date: $formattedDate',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.indigo900, thickness: 1.5),
              pw.SizedBox(height: 15),

              // Student & Program Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORMATII CLIENT & PROGRAM / CLIENT & PROGRAM DETAILS',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.black),
                              children: [
                                const pw.TextSpan(
                                    text: 'Cursant / Student: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: studentName),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.black),
                              children: [
                                const pw.TextSpan(
                                    text: 'Email: ',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.TextSpan(text: studentEmail),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.black),
                        children: [
                          const pw.TextSpan(
                              text: 'Program Mentorat / Program: ',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)),
                          pw.TextSpan(text: programName),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Payment Breakdown Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                    children: [
                      _buildHeaderCell('Descriere / Description'),
                      _buildHeaderCell('Rata / Installment'),
                      _buildHeaderCell('Metoda / Method'),
                      _buildHeaderCell('Suma / Amount'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell(
                          'Plata rata mentorat / Mentorship fee installment payment'),
                      _buildTableCell('Rata $installmentNumber din $totalInstallments'),
                      _buildTableCell(paymentMethod),
                      _buildTableCell(formattedAmount, alignRight: true),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              // Transaction Reference if present
              if (transactionReference != null &&
                  transactionReference.isNotEmpty) ...[
                pw.Text(
                  'Referinta tranzactie / Transaction Ref: $transactionReference',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 15),
              ],

              // Total Paid Highlight Box
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.indigo200),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'TOTAL ACHITAT / TOTAL PAID: ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.Text(
                        formattedAmount,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // Mentor Signature Block & Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Confirmare Plata / Payment Confirmation',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Prezenta chitanta atesta primirea sumei mentionate mai sus.',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'This receipt confirms receipt of the amount stated above.',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Semnatura Mentor / Signature',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      if (signatureImage != null)
                        pw.Container(
                          height: 40,
                          child: pw.Image(signatureImage),
                        )
                      else
                        pw.Container(
                          height: 40,
                          width: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.grey400, style: pw.BorderStyle.dashed),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'Semnat / Signed',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey500),
                          ),
                        ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'QualiAdept SRL',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),

              // Footer Note
              pw.Center(
                child: pw.Text(
                  'Agreemint (c) ${DateTime.now().year} QualiAdept. Generat automat / Automatically generated.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
      ),
    );
  }
}
