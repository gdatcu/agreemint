import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/invoice_smart_link_parser.dart';

void main() {
  group('InvoiceSmartLinkParser - URL Parsing & Series Extraction', () {
    test('parses standard SOLO invoice URL with series and number', () {
      const url = 'https://app.solo.ro/invoices/SL-10492';
      final result = InvoiceSmartLinkParser.parse(url);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-10492');
      expect(result.invoiceUrl, url);
      expect(result.series, 'SL');
      expect(result.number, '10492');
      expect(result.platform, InvoicePlatform.solo);
      expect(result.isSolo, isTrue);
    });

    test('parses SOLO invoice URL with pure number', () {
      const url = 'https://solo.ro/i/10492';
      final result = InvoiceSmartLinkParser.parse(url);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-10492');
      expect(result.invoiceUrl, url);
      expect(result.number, '10492');
      expect(result.platform, InvoicePlatform.solo);
    });

    test('parses SOLO invoice URL with year in series', () {
      const url = 'https://app.solo.ro/factura/SL-2024-10492?auth=abc123xyz';
      final result = InvoiceSmartLinkParser.parse(url);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-2024-10492');
      expect(result.invoiceUrl, url);
      expect(result.series, 'SL-2024');
      expect(result.number, '10492');
      expect(result.platform, InvoicePlatform.solo);
    });

    test('parses invoice URL with query parameters', () {
      const url = 'https://portal.billing.com/view?series=QUAL&nr=8821';
      final result = InvoiceSmartLinkParser.parse(url);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'QUAL-8821');
      expect(result.series, 'QUAL');
      expect(result.number, '8821');
      expect(result.invoiceUrl, url);
    });

    test('parses PDF storage URL with invoice file name', () {
      const url =
          'https://xyz.supabase.co/storage/v1/object/public/invoices/factura_SL_10492.pdf';
      final result = InvoiceSmartLinkParser.parse(url);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-10492');
      expect(result.invoiceUrl, url);
      expect(result.series, 'SL');
      expect(result.number, '10492');
    });
  });

  group('InvoiceSmartLinkParser - Romanian Text & Message Extraction', () {
    test('extracts series and number from formal Romanian text', () {
      const text =
          'Factura seria SL nr. 10492 din data de 15.10.2024 in valoare de 1500 RON';
      final result = InvoiceSmartLinkParser.parse(text);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-10492');
      expect(result.series, 'SL');
      expect(result.number, '10492');
      expect(result.amount, 1500.0);
      expect(result.currency, 'RON');
      expect(result.issueDate, DateTime(2024, 10, 15));
    });

    test('extracts from multi-line WhatsApp message with SOLO link', () {
      const text = '''
Buna George!
Am emis factura fiscala seria SL numarul 10492 din 15.10.2024.
Valoare: 1.850,50 LEI
O poti descarca direct de aici: https://app.solo.ro/invoices/SL-10492/download
Multumesc!
''';
      final result = InvoiceSmartLinkParser.parse(text);

      expect(result.isValid, isTrue);
      expect(result.invoiceNumber, 'SL-10492');
      expect(result.invoiceUrl,
          'https://app.solo.ro/invoices/SL-10492/download');
      expect(result.series, 'SL');
      expect(result.number, '10492');
      expect(result.amount, 1850.50);
      expect(result.currency, 'RON');
      expect(result.issueDate, DateTime(2024, 10, 15));
      expect(result.platform, InvoicePlatform.solo);
    });

    test('extracts from token format like SOLO-10492 and EUR amount', () {
      const text = 'SOLO-10492 achitat suma de 350 EUR';
      final result = InvoiceSmartLinkParser.parse(text);

      expect(result.invoiceNumber, 'SOLO-10492');
      expect(result.series, 'SOLO');
      expect(result.number, '10492');
      expect(result.amount, 350.0);
      expect(result.currency, 'EUR');
    });

    test('extracts from Factura #10492 with default prefix', () {
      const text = 'Factura #10492';
      final result = InvoiceSmartLinkParser.parse(text);

      expect(result.invoiceNumber, 'SOLO-10492');
      expect(result.number, '10492');
    });

    test('detects Smartbill and Oblio platforms cleanly', () {
      final sb = InvoiceSmartLinkParser.parse(
          'Factura emisa pe smartbill.ro seria SB nr 441');
      expect(sb.platform, InvoicePlatform.smartbill);
      expect(sb.invoiceNumber, 'SB-441');

      final oblio = InvoiceSmartLinkParser.parse(
          'https://oblio.eu/invoices/view/OBL-901');
      expect(oblio.platform, InvoicePlatform.oblio);
      expect(oblio.invoiceNumber, 'OBL-901');
    });
  });

  group('InvoiceSmartLinkParser - Edge Cases & Normalization', () {
    test('handles empty and whitespace input', () {
      final result = InvoiceSmartLinkParser.parse('   ');
      expect(result.isValid, isFalse);
      expect(result.invoiceNumber, isNull);
      expect(result.invoiceUrl, isNull);
    });

    test('cleans trailing punctuation from URLs', () {
      const input =
          'Factura se afla la https://app.solo.ro/invoices/SL-10492.';
      final result = InvoiceSmartLinkParser.parse(input);

      expect(result.invoiceUrl, 'https://app.solo.ro/invoices/SL-10492');
      expect(result.invoiceNumber, 'SL-10492');
    });

    test('isLikelyInvoiceLinkOrText identifies invoice texts correctly', () {
      expect(InvoiceSmartLinkParser.isLikelyInvoiceLinkOrText('https://app.solo.ro/i/123'), isTrue);
      expect(InvoiceSmartLinkParser.isLikelyInvoiceLinkOrText('SL-10492'), isTrue);
      expect(InvoiceSmartLinkParser.isLikelyInvoiceLinkOrText('Factura seria SL nr 12'), isTrue);
      expect(InvoiceSmartLinkParser.isLikelyInvoiceLinkOrText('Hello world'), isFalse);
      expect(InvoiceSmartLinkParser.isLikelyInvoiceLinkOrText(''), isFalse);
    });

    test('normalizeInvoiceNumber standardizes series and number', () {
      expect(InvoiceSmartLinkParser.normalizeInvoiceNumber('SL', '10492'), 'SL-10492');
      expect(InvoiceSmartLinkParser.normalizeInvoiceNumber('SL-', '10492'), 'SL-10492');
      expect(InvoiceSmartLinkParser.normalizeInvoiceNumber('SOLO', '99'), 'SOLO-99');
      expect(InvoiceSmartLinkParser.normalizeInvoiceNumber('', '99'), '99');
    });
  });
}
