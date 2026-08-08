import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGeneratorService {
  /// Generates a structured Bilingual (RO-EN) Mentorship Agreement PDF
  /// featuring the QualiAdept header logo and 2-party signature workflow.
  Future<Uint8List> generateContractPdf({
    required String contractNumber,
    required DateTime date,
    required String studentName,
    required String adresaCursant,
    required String cnpCursant,
    required String serieNrCi,
    required String eliberatorCi,
    required String dataEliberariiCi,
    required String emailCursant,
    required String telefonCursant,
    required String programName,
    required String editionName,
    required int durataOre,
    required int nrSesiuni,
    required String dataIncepere,
    required String frecventa,
    required double priceRon,
    required String priceLitere,
    required String modalitatePlata,
    required String prestatorNume,
    required String prestatorSediu,
    required String prestatorRegCom,
    required String prestatorCif,
    String prestatorEuid = 'ROONRC.F2026003426005',
    required String prestatorIban,
    required String prestatorBanca,
    String clientType = 'PF',
    String? cuiCursant,
    String? regComCursant,
    String? billingAddressCursant,
    String? technologiesCurriculum,
    String? beneficiaryEntity,
    String? serviceDescription,
    String? paymentTerm,
    String? refundDeadline,
    Uint8List? mentorSignatureBytes,
    Uint8List? clientSignatureBytes,
  }) async {
    // Load Unicode fonts supporting Romanian diacritics
    pw.Font baseFont = pw.Font.helvetica();
    pw.Font boldFont = pw.Font.helveticaBold();
    pw.Font italicFont = pw.Font.helveticaOblique();
    try {
      baseFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (_) {}

    // Load QualiAdept logo asset
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/qualiAdept_logo_1.jpg');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Fallback silently if asset loading encounters platform difference
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
        fontFallback: [baseFont],
      ),
    );
    final formattedDate = date.toLocal().toString().split(' ')[0];

    final hasMentorSig =
        mentorSignatureBytes != null && mentorSignatureBytes.isNotEmpty;
    final hasClientSig =
        clientSignatureBytes != null && clientSignatureBytes.isNotEmpty;

    final mentorSignatureImage =
        hasMentorSig ? pw.MemoryImage(mentorSignatureBytes) : null;
    final clientSignatureImage =
        hasClientSig ? pw.MemoryImage(clientSignatureBytes) : null;

    final techCurriculum = technologiesCurriculum ?? 'QA Automation';
    final benEntity = beneficiaryEntity ?? 'QualiAdept Community';
    final svcDesc = serviceDescription ??
        'sesiuni live online, feedback pe cod (code review) și consultanță / live online sessions, code reviews and consulting';
    final payTerm = paymentTerm ?? '3 (trei) zile calendaristice / 3 calendar days';
    final refDeadline = refundDeadline ?? '5 zile calendaristice / 5 calendar days';

    final isB2bClient = clientType == 'PFA' || clientType == 'SRL';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with Logo and Contract Serial Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    height: 38,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Text(
                    'QualiAdept',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CONTRACT DE PRESTARI SERVICII DE MENTORAT TEHNIC',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'TECHNICAL MENTORING SERVICES CONTRACT',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Nr. / No. $contractNumber | Data / Date: $formattedDate',
                      style: pw.TextStyle(
                          fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 12),

            // 1. PARTILE CONTRACTANTE / THE CONTRACTING PARTIES
            pw.Text(
              '1. PARTILE CONTRACTANTE / THE CONTRACTING PARTIES',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 8),
                children: [
                  pw.TextSpan(
                    text: '1.1. PRESTATORUL / PROVIDER: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(
                    text:
                        '$prestatorNume, sediu profesional in $prestatorSediu, Reg. Com. nr. $prestatorRegCom, EUID: $prestatorEuid, CUI/CIF: $prestatorCif, reprezentata legal prin Datcu George-Cristian, IBAN: $prestatorIban ($prestatorBanca), denumita "Prestator" / hereinafter "Provider".\n\n'
                        'si / and\n\n',
                  ),
                  pw.TextSpan(
                    text: '1.2. BENEFICIARUL / BENEFICIARY:\n',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(
                    text: isB2bClient
                        ? '- Denumire / Entity Name: $studentName\n'
                          '- CUI/CIF: ${cuiCursant ?? "N/A"}\n'
                          '- Reg. Com. / Reg. Com. No.: ${regComCursant ?? "N/A"}\n'
                          '- Adresa / Address: ${(billingAddressCursant != null && billingAddressCursant.isNotEmpty) ? billingAddressCursant : adresaCursant}\n'
                          '- Email: $emailCursant | Telefon / Phone: $telefonCursant\n\n'
                        : '- Nume si Prenume / Full Name: $studentName\n'
                          '- Adresa / Address: $adresaCursant\n'
                          '- CNP: $cnpCursant | Serie & Nr. CI / IC Series & No: $serieNrCi (eliberat de / issued by $eliberatorCi la / on $dataEliberariiCi)\n'
                          '- Email: $emailCursant | Telefon / Phone: $telefonCursant\n\n',
                  ),
                  const pw.TextSpan(
                    text:
                        'Denumit in continuare "Beneficiar" sau "Cursant" / hereinafter "Beneficiary" or "Student". Partile au convenit incheierea prezentului contract / The parties agreed to conclude this contract:',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // 2. OBIECTUL CONTRACTULUI / SUBJECT OF THE CONTRACT
            pw.Text(
              '2. OBIECTUL CONTRACTULUI / SUBJECT OF THE CONTRACT',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '2.1. Obiectul prezentului Contract il reprezinta prestarea serviciilor de mentorat tehnic, consultanta practica si indrumare educationala in domeniul testarii software (QA Automation), denumit "$programName".\n'
              'The subject of this Contract is technical mentoring, practical consulting, and educational guidance services in QA Automation, hereinafter referred to as "$programName".\n\n'
              '2.2. $programName consta in $editionName a modulului bazat pe $techCurriculum, desfasurat exclusiv pentru $benEntity.\n'
              '$programName consists of $editionName of the learning module based on $techCurriculum, developed exclusively for $benEntity.\n\n'
              '2.3. Serviciile vor fi prestate sub forma de $svcDesc. Durata estimata: $durataOre ore ($nrSesiuni sesiuni). Data inceperii: $dataIncepere ($frecventa).\n'
              'Services will be provided as $svcDesc. Estimated duration: $durataOre hours ($nrSesiuni sessions). Start date: $dataIncepere ($frecventa).',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 3. PRETUL SI MODALITATEA DE PLATA / PRICE AND PAYMENT METHOD
            pw.Text(
              '3. PRETUL SI MODALITATEA DE PLATA / PRICE AND PAYMENT METHOD',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '3.1. Pretul total este de ${priceRon.toStringAsFixed(2)} RON ($priceLitere lei), reprezentand un pret preferential acordat exclusiv Beneficiarului.\n'
              'The total price is ${priceRon.toStringAsFixed(2)} RON ($priceLitere), representing a preferential price granted exclusively to the Beneficiary.\n\n'
              '3.2. Plata se va efectua $modalitatePlata in contul Prestatorului mentionat la Art. 1.1., in termen de maxim $payTerm de la data emiterii facturii.\n'
              'Payment shall be made $modalitatePlata to the Provider\'s account within $payTerm from invoice issuance.\n\n'
              '3.3. Factura fiscala va fi transmisa pe adresa de email furnizata imediat dupa semnarea contractului.\n'
              'The tax invoice will be sent to the provided email immediately after contract signing.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 4. OBLIGATIILE PARTILOR / OBLIGATIONS OF THE PARTIES
            pw.Text(
              '4. OBLIGATIILE PARTILOR / OBLIGATIONS OF THE PARTIES',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '4.1. Obligatiile Prestatorului / Provider\'s Obligations:\n'
              '- a) Sa livreze sesiunile la standarde profesionale inalte / Deliver sessions to high professional standards.\n'
              '- b) Sa stabileasca data de incepere de comun acord / Establish course start date by mutual agreement.\n'
              '- c) Sa puna la dispozitie inregistrarile sesiunilor live (pentru vizionare personala) / Provide recordings for personal viewing.\n'
              '- d) Declara pe proprie raspundere ca materialele predate sunt originale / Declares taught materials represent original work.\n\n'
              '4.2. Obligatiile Beneficiarului / Beneficiary\'s Obligations:\n'
              '- a) Sa achite pretul integral la termenul stabilit / Pay full price by the agreed deadline.\n'
              '- b) Sa participe activ la sesiunile live (prezenta recomandata 75%) / Actively participate (target 75% attendance).\n'
              '- c) Sa ofere feedback constructiv / Provide constructive feedback.\n'
              '- d) Sa ofere o recenzie (testimonial video sau scris) la finalizarea Programului / Provide a review/testimonial upon completion.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 5. DREPTURI DE PROPRIETATE INTELECTUALA / INTELLECTUAL PROPERTY RIGHTS
            pw.Text(
              '5. DREPTURI DE PROPRIETATE INTELECTUALA / INTELLECTUAL PROPERTY RIGHTS',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '5.1. Materialele puse la dispozitie reprezinta proprietatea intelectuala exclusiva a Prestatorului.\n'
              'All materials provided represent the exclusive intellectual property of the Provider.\n'
              '5.2. Beneficiarul le foloseste strict in scop personal si educational / Strictly for personal and educational use.\n'
              '5.3. Este interzisa copierea, distribuirea sau publicarea materialelor / Reproduction, copying, or distribution is prohibited.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 6. GDPR & AUDIO-VIDEO RECORDINGS
            pw.Text(
              '6. GDPR SI INREGISTRARI AUDIO-VIDEO / GDPR AND AUDIO-VIDEO RECORDINGS',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '6.1. Beneficiarul este de acord cu prelucrarea datelor personale in scopul executarii contractului.\n'
              'The Beneficiary consents to personal data processing for contract execution.\n'
              '6.2. Simultan consimtamant explicit pentru inregistrare audio-video in timpul sesiunilor live (scop educational intern).\n'
              'Explicit consent to audio-video recording during live sessions for internal educational purposes.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 7. POLITICA DE ANULARE SI RAMBURSARE / CANCELLATION AND REFUND POLICY
            pw.Text(
              '7. POLITICA DE ANULARE SI RAMBURSARE / CANCELLATION AND REFUND POLICY',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '7.1. Retragere si rambursare integrala cu pana la $refDeadline inainte de prima sesiune live.\n'
              'Withdrawal and full refund up to $refDeadline before the first live session.\n'
              '7.2. Dupa inceperea Programului nu se efectueaza rambursari / No refunds are granted after Program start.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 8. INCETAREA CONTRACTULUI SI FORTA MAJORA / TERMINATION AND FORCE MAJEURE
            pw.Text(
              '8. INCETAREA CONTRACTULUI SI FORTA MAJORA / TERMINATION AND FORCE MAJEURE',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '8.1. Contractul inceteaza la finalizarea orelor de mentorat / Contract terminates upon mentoring completion.\n'
              '8.2. Reziliere unilaterala in caz de neplata sau incalcare GDPR/Proprietate Intelectuala / Unilateral termination on non-payment or IP breach.\n'
              '8.3. Forta majora apara de raspundere conform legii / Force majeure releases liability under the law.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 10),

            // 9. DISPOZITII FINALE / FINAL PROVISIONS
            pw.Text(
              '9. DISPOZITII FINALE / FINAL PROVISIONS',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '9.1. Prezentul contract a fost agreat la distanta. Transmiterea semnata reprezinta acceptarea integrala.\n'
              'Agreed via distance communication. Signed transmission represents full acceptance.\n'
              '9.2. Neintelegerile se rezolva pe cale amiabila / Disagreements will be resolved amicably.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 16),

            // Signatures block (2-Party)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // PRESTATOR / PROVIDER
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PRESTATOR / PROVIDER:',
                      style: pw.TextStyle(
                          fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      prestatorNume,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 6),
                    if (mentorSignatureImage != null)
                      pw.Container(
                        height: 40,
                        width: 120,
                        child: pw.Image(mentorSignatureImage,
                            fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        height: 40,
                        width: 120,
                        alignment: pw.Alignment.bottomLeft,
                        child: pw.Text(
                          '______________________',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700),
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Semnatura / Signature',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ],
                ),
                // BENEFICIAR / BENEFICIARY
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BENEFICIAR / BENEFICIARY:',
                      style: pw.TextStyle(
                          fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      studentName,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 6),
                    if (clientSignatureImage != null)
                      pw.Container(
                        height: 40,
                        width: 120,
                        child: pw.Image(clientSignatureImage,
                            fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        height: 40,
                        width: 120,
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(
                          'Pending Client Signature',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.orange800,
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Semnatura & Data / Signature & Date',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
