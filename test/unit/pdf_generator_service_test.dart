import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/features/contracts/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfGeneratorService Comprehensive Coverage Unit Tests', () {
    test('generateContractPdf builds full bilingual PDF with signatures', () async {
      final service = PdfGeneratorService();

      // Dummy PNG signature byte array (1x1 pixel)
      final dummySig = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      final pdfBytes = await service.generateContractPdf(
        contractNumber: '101',
        date: DateTime.now(),
        studentName: 'Ion Popescu',
        adresaCursant: 'Strada Florilor Nr 5, Bucuresti',
        cnpCursant: '1900101123456',
        serieNrCi: 'RR123456',
        eliberatorCi: 'SPCLEP Sec 1',
        dataEliberariiCi: '2020-01-01',
        emailCursant: 'ion@example.com',
        telefonCursant: '+40712345678',
        programName: 'Full Stack Mentorship',
        editionName: 'Editia Iulie 2026',
        durataOre: 120,
        nrSesiuni: 24,
        dataIncepere: '2026-08-01',
        frecventa: '2 ori pe saptamana',
        priceRon: 5000.0,
        priceLitere: 'Cinci mii RON',
        modalitatePlata: 'Transfer bancar in 2 transe',
        prestatorNume: 'QualiAdept SRL',
        prestatorSediu: 'Str. Victoriei Nr. 10, Bucuresti',
        prestatorRegCom: 'J40/1234/2025',
        prestatorCif: 'RO12345678',
        prestatorIban: 'RO98AAAA1234567890123456',
        prestatorBanca: 'Banca Transilvania',
        technologiesCurriculum: 'Flutter, Dart, Supabase, PostgreSQL',
        beneficiaryEntity: 'Beneficiar Persoana Fizica',
        serviceDescription: 'Servicii de consultanta si mentorat educational',
        paymentTerm: 'La 14 zile de la emitere',
        refundDeadline: '14 zile de la prima sesiune',
        mentorSignatureBytes: dummySig,
        clientSignatureBytes: dummySig,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
