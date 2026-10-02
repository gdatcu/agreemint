import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agreemint/core/services/anaf_service.dart';

void main() {
  group('AnafService CUI Sanitization & Validation', () {
    test('sanitizes various CUI formats correctly', () {
      expect(AnafService.sanitizeCui('RO 12345678'), '12345678');
      expect(AnafService.sanitizeCui('ro53430793'), '53430793');
      expect(AnafService.sanitizeCui(' RO-998877 '), '998877');
      expect(AnafService.sanitizeCui('123456'), '123456');
    });

    test('throws AnafException on empty or invalid length CUI', () async {
      expect(
        () => AnafService.lookupCompany(''),
        throwsA(isA<AnafException>()),
      );
      expect(
        () => AnafService.lookupCompany('RO'),
        throwsA(isA<AnafException>()),
      );
      expect(
        () => AnafService.lookupCompany('1'),
        throwsA(isA<AnafException>()),
      );
      expect(
        () => AnafService.lookupCompany('123456789012345'),
        throwsA(isA<AnafException>()),
      );
    });
  });

  group('AnafService API Mock Parsing', () {
    test('successfully parses active VAT paying company', () async {
      final mockResponse = {
        'cod': 200,
        'message': 'SUCCESS',
        'found': [
          {
            'date_generale': {
              'cui': 53430793,
              'denumire': 'QUALIADEPT SOLUTIONS S.R.L.',
              'adresa': 'MUNICIPIUL BUCURESTI, SECTOR 1, STR. EXEMPLU NR. 42',
              'nrRegCom': 'J40/12345/2023',
              'telefon': '0712345678',
              'codPostal': '010101',
              'stare_inregistrare': 'INREGISTRAT',
              'statusInactivi': false,
            },
            'inregistrare_scop_Tva': {
              'scpTVA': true,
            },
          }
        ],
        'notfound': []
      };

      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            'https://webservicesp.anaf.ro/api/PlatitorTvaRest/v9/tva');
        expect(request.headers['Content-Type'], 'application/json');
        final decoded = jsonDecode(request.body) as List;
        expect(decoded.first['cui'], 53430793);

        return http.Response(jsonEncode(mockResponse), 200);
      });

      final details = await AnafService.lookupCompany(
        'RO 53430793',
        httpClient: mockClient,
      );

      expect(details.cui, '53430793');
      expect(details.denumire, 'QUALIADEPT SOLUTIONS S.R.L.');
      expect(details.nrRegCom, 'J40/12345/2023');
      expect(details.adresa,
          'MUNICIPIUL BUCURESTI, SECTOR 1, STR. EXEMPLU NR. 42');
      expect(details.telefon, '0712345678');
      expect(details.isPlatitorTva, isTrue);
      expect(details.tvaBadge, 'Plătitor TVA');
      expect(details.isInactiv, isFalse);
    });

    test('throws AnafException when company is not found in ANAF', () async {
      final mockResponse = {
        'cod': 200,
        'message': 'SUCCESS',
        'found': [],
        'notfound': [
          {'cui': 99999999, 'data': '2026-10-02'}
        ]
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      expect(
        () => AnafService.lookupCompany('99999999', httpClient: mockClient),
        throwsA(predicate((e) =>
            e is AnafException &&
            e.message.contains('nu a fost găsit'))),
      );
    });

    test('parses non-VAT payer and inactive company correctly', () async {
      final mockResponse = {
        'cod': 200,
        'message': 'SUCCESS',
        'found': [
          {
            'date_generale': {
              'cui': 11223344,
              'denumire': 'OLD VENTURES PFA',
              'adresa': 'SAT TEST, JUD. ILFOV',
              'nrRegCom': 'F23/10/2018',
              'statusInactivi': true,
            },
            'inregistrare_scop_Tva': {
              'scpTVA': false,
            },
          }
        ],
        'notfound': []
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final details = await AnafService.lookupCompany(
        '11223344',
        httpClient: mockClient,
      );

      expect(details.isPlatitorTva, isFalse);
      expect(details.tvaBadge, 'Neplătitor TVA');
      expect(details.isInactiv, isTrue);
    });
  });
}
