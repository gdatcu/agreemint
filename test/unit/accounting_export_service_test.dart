import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/accounting_export_service.dart';

void main() {
  group('AccountingExportService Unit Tests', () {
    test('generateCsvContent generates valid Romanian accounting CSV header and formatted rows', () {
      final records = [
        const AccountingRecord(
          paymentDate: '2026-08-17',
          clientName: 'Popescu Ion (SC TECH SRL)',
          clientType: 'SRL',
          cuiCif: 'RO12345678',
          regCom: 'J40/1234/2020',
          programName: 'Mentorat Fullstack',
          installmentInfo: 'Transa 1',
          amountPaid: 2500.0,
          currency: 'RON',
          amountPaidInRon: 2500.0,
          paymentMethod: 'Transfer Bancar',
          soloInvoiceNumber: 'GD-17-26',
          soloInvoiceUrl: 'https://solo.ro/inv/123',
          receiptUrl: 'https://supabase.co/receipt/123',
        ),
      ];

      final csv = AccountingExportService.generateCsvContent(records);

      expect(csv, contains('Data Platii,Nume Client / Firma,Tip Client,CUI / CIF'));
      expect(csv, contains('2026-08-17,Popescu Ion (SC TECH SRL),SRL,RO12345678,J40/1234/2020,Mentorat Fullstack,Transa 1,2500.00,RON,2500.00,Transfer Bancar,GD-17-26'));
      expect(csv, contains('https://solo.ro/inv/123'));
    });

    test('generateCsvContent handles special characters and quotes correctly', () {
      final records = [
        const AccountingRecord(
          paymentDate: '2026-08-18',
          clientName: 'Ana-Maria "Elena" Pop',
          clientType: 'PFA',
          cuiCif: 'RO98765432',
          regCom: 'F40/999/2021',
          programName: 'Program, Special',
          installmentInfo: 'Transa 2',
          amountPaid: 500.0,
          currency: 'EUR',
          amountPaidInRon: 2487.50,
          paymentMethod: 'Card',
          soloInvoiceNumber: '-',
          soloInvoiceUrl: '',
          receiptUrl: '',
        ),
      ];

      final csv = AccountingExportService.generateCsvContent(records);

      expect(csv, contains('"Ana-Maria ""Elena"" Pop"'));
      expect(csv, contains('"Program, Special"'));
      expect(csv, contains('2487.50'));
    });
  });
}
