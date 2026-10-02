import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when an ANAF lookup fails.
class AnafException implements Exception {
  final String message;
  const AnafException(this.message);

  @override
  String toString() => message;
}

/// Represents the company information retrieved from Romania's ANAF registry.
class AnafCompanyDetails {
  final String cui;
  final String denumire;
  final String adresa;
  final String nrRegCom;
  final String? telefon;
  final String? codPostal;
  final bool isPlatitorTva;
  final bool isInactiv;
  final String stareInregistrare;

  const AnafCompanyDetails({
    required this.cui,
    required this.denumire,
    required this.adresa,
    required this.nrRegCom,
    this.telefon,
    this.codPostal,
    required this.isPlatitorTva,
    required this.isInactiv,
    required this.stareInregistrare,
  });

  /// Formatted summary suitable for toast notifications or subtitle chips
  String get tvaBadge => isPlatitorTva ? 'Plătitor TVA' : 'Neplătitor TVA';

  @override
  String toString() =>
      'AnafCompanyDetails(denumire: $denumire, cui: $cui, regCom: $nrRegCom, tva: $tvaBadge, adresa: $adresa)';
}

/// Service providing 100% free lookup of Romanian company fiscal data via
/// the official ANAF Public Web Service v9.
class AnafService {
  /// Official ANAF TVA V9 Web Service endpoint
  static const String _anafUrl =
      'https://webservicesp.anaf.ro/api/PlatitorTvaRest/v9/tva';

  /// Sanitizes raw CUI string by stripping 'RO', whitespace, and non-digit characters.
  static String sanitizeCui(String rawCui) {
    return rawCui
        .trim()
        .toUpperCase()
        .replaceAll('RO', '')
        .replaceAll(RegExp(r'\D'), '');
  }

  /// Parses the raw ANAF JSON response structure.
  static AnafCompanyDetails parseAnafResponse(
    Map<String, dynamic> data,
    String cleanCui,
  ) {
    final foundList = data['found'] as List<dynamic>?;
    if (foundList == null || foundList.isEmpty) {
      throw const AnafException(
        'Codul fiscal nu a fost găsit în registrul ANAF.',
      );
    }

    final Map<String, dynamic> record =
        Map<String, dynamic>.from(foundList.first as Map);
    final general = Map<String, dynamic>.from(
      (record['date_generale'] as Map?) ?? {},
    );

    final denumire = (general['denumire'] as String?)?.trim() ?? '';
    if (denumire.isEmpty) {
      throw const AnafException(
        'Nu s-au putut extrage datele de identificare ale companiei din ANAF.',
      );
    }

    final adresa = (general['adresa'] as String?)?.trim() ?? '';
    final nrRegCom = (general['nrRegCom'] as String?)?.trim() ?? '';
    final telefon = (general['telefon'] as String?)?.trim();
    final codPostal = (general['codPostal'] as String?)?.trim();
    final stareInregistrare =
        (general['stare_inregistrare'] as String?)?.trim() ?? '';

    // VAT status
    final tvaObj = Map<String, dynamic>.from(
      (record['inregistrare_scop_Tva'] as Map?) ?? {},
    );
    final isPlatitorTva = tvaObj['scpTVA'] == true;

    // Inactivity status
    final statusInactivi = general['statusInactivi'] == true ||
        (record['stare_inactiv'] is Map &&
            (record['stare_inactiv'] as Map)['statusInactivi'] == true);

    return AnafCompanyDetails(
      cui: cleanCui,
      denumire: denumire,
      adresa: adresa,
      nrRegCom: nrRegCom,
      telefon: (telefon != null && telefon.isNotEmpty) ? telefon : null,
      codPostal: (codPostal != null && codPostal.isNotEmpty) ? codPostal : null,
      isPlatitorTva: isPlatitorTva,
      isInactiv: statusInactivi,
      stareInregistrare: stareInregistrare,
    );
  }

  /// Looks up official company details from ANAF for a given CUI/CIF.
  ///
  /// On Web (where browser CORS blocks direct third-party HTTP POST), this dispatches
  /// through a robust cascading relay strategy (apps.qualiadept.eu, onrender bot, direct, or Supabase).
  /// On Native platforms (Android, iOS, Desktop), it calls ANAF V9 directly.
  static Future<AnafCompanyDetails> lookupCompany(
    String rawCui, {
    http.Client? httpClient,
  }) async {
    final cleanCui = sanitizeCui(rawCui);

    if (cleanCui.isEmpty || cleanCui.length < 2 || cleanCui.length > 10) {
      throw const AnafException(
        'CUI invalid. Introduceți un cod fiscal valid (2-10 cifre).',
      );
    }

    final cuiInt = int.tryParse(cleanCui);
    if (cuiInt == null) {
      throw const AnafException('CUI invalid. Trebuie să conțină doar cifre.');
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Web Dispatch: Handles browser CORS via server relays and direct fallback
    if (kIsWeb && httpClient == null) {
      // Step A: Try QualiAdept production web server relay (apps.qualiadept.eu)
      try {
        final client = http.Client();
        final uri = Uri.parse(
          'https://apps.qualiadept.eu/agreemint/api/anaf.php?cui=$cleanCui',
        );
        final response =
            await client.get(uri).timeout(const Duration(seconds: 8));
        client.close();
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return parseAnafResponse(data, cleanCui);
        }
      } catch (e) {
        debugPrint('[AnafService] apps.qualiadept.eu proxy notice: $e');
      }

      // Step B: Try WhatsApp Bot server relay (Render Cloud)
      try {
        final client = http.Client();
        final botUri = Uri.parse(
          'https://qualiadept-whatsapp-bot.onrender.com/api/anaf/$cleanCui',
        );
        final response =
            await client.get(botUri).timeout(const Duration(seconds: 8));
        client.close();
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return parseAnafResponse(data, cleanCui);
        }
      } catch (e) {
        debugPrint('[AnafService] Render bot proxy notice: $e');
      }

      // Step C: Try local node server if running (localhost:3000)
      try {
        final client = http.Client();
        final localUri =
            Uri.parse('http://localhost:3000/api/anaf/$cleanCui');
        final response =
            await client.get(localUri).timeout(const Duration(seconds: 3));
        client.close();
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return parseAnafResponse(data, cleanCui);
        }
      } catch (_) {}

      // Step D: Direct fetch (succeeds in Chrome if launched with --disable-web-security)
      try {
        final client = http.Client();
        final response = await client
            .post(
              Uri.parse(_anafUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode([
                {'cui': cuiInt, 'data': dateStr}
              ]),
            )
            .timeout(const Duration(seconds: 8));
        client.close();
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          return parseAnafResponse(data, cleanCui);
        }
      } catch (e) {
        debugPrint('[AnafService] Direct web fetch notice: $e');
      }

      // Step E: Try Supabase RPC
      try {
        final supabase = Supabase.instance.client;
        final rpcRes = await supabase.rpc(
          'lookup_cui_anaf',
          params: {
            'p_cui': cuiInt,
            'p_date': dateStr,
          },
        );

        if (rpcRes != null) {
          final Map<String, dynamic> data = (rpcRes is String)
              ? jsonDecode(rpcRes) as Map<String, dynamic>
              : Map<String, dynamic>.from(rpcRes as Map);

          if (data.containsKey('error')) {
            throw AnafException(data['error'].toString());
          }
          return parseAnafResponse(data, cleanCui);
        }
      } catch (e) {
        debugPrint('[AnafService] Supabase RPC notice: $e');
      }

      throw const AnafException(
        'Pe Web este activă restricția CORS de browser. Pentru testare locală în Chrome rulați:\nflutter run -d chrome --web-browser-flag "--disable-web-security"\n(în producție funcționează automat pe apps.qualiadept.eu).',
      );
    }

    // 2. Direct HTTP dispatch for Native platforms (Android, iOS, Desktop) and custom test clients
    final requestBody = jsonEncode([
      {
        'cui': cuiInt,
        'data': dateStr,
      }
    ]);

    final client = httpClient ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(_anafUrl),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw AnafException(
          'Eroare la comunicarea cu serverul ANAF (HTTP ${response.statusCode}).',
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return parseAnafResponse(data, cleanCui);
    } on AnafException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('ANAF lookup error: $e');
      }
      throw AnafException('Nu s-a putut interoga ANAF: ${e.toString()}');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
