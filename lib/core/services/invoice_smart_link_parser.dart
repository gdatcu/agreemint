import 'package:flutter/foundation.dart';

/// Supported invoicing platforms detected by the smart link parser.
enum InvoicePlatform {
  solo,
  smartbill,
  oblio,
  fgo,
  generic,
}

/// Structured outcome of parsing an invoice link or raw text snippet.
class ParsedInvoiceResult {
  /// Normalized invoice identifier, e.g. "SL-10492" or "SOLO-10492".
  final String? invoiceNumber;

  /// Full clean URL linking to the invoice (view, download, or PDF).
  final String? invoiceUrl;

  /// Extracted series (e.g. "SL", "SOLO", "QUAL").
  final String? series;

  /// Extracted numerical sequence (e.g. "10492").
  final String? number;

  /// Extracted monetary amount, if present in text (e.g. 1500.0).
  final double? amount;

  /// Extracted currency (e.g. "RON", "EUR").
  final String? currency;

  /// Extracted issue/due date, if detected.
  final DateTime? issueDate;

  /// Platform detected from domain or series prefixes.
  final InvoicePlatform platform;

  /// Original raw input text.
  final String rawInput;

  /// Indicates whether an explicit series was present vs inferred.
  final bool hasExplicitSeries;

  const ParsedInvoiceResult({
    this.invoiceNumber,
    this.invoiceUrl,
    this.series,
    this.number,
    this.amount,
    this.currency,
    this.issueDate,
    this.platform = InvoicePlatform.generic,
    required this.rawInput,
    this.hasExplicitSeries = false,
  });

  bool get hasNumber =>
      invoiceNumber != null && invoiceNumber!.trim().isNotEmpty;

  bool get hasUrl => invoiceUrl != null && invoiceUrl!.trim().isNotEmpty;

  bool get isValid => hasNumber || hasUrl;

  bool get isSolo => platform == InvoicePlatform.solo;

  @override
  String toString() =>
      'ParsedInvoiceResult(number: $invoiceNumber, url: $invoiceUrl, platform: $platform, amount: $amount $currency)';
}

/// Smart parser designed to detect, extract, and normalize SOLO invoices,
/// invoice URLs, series numbers, amounts, and dates from raw clipboard text,
/// links, or multi-line WhatsApp/email messages.
class InvoiceSmartLinkParser {
  /// Regex pattern to extract web URLs.
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/[^\s<>"]+',
    caseSensitive: false,
  );

  /// Series with Year + number (e.g. SL-2024-10492 or SL/2024/10492)
  static final RegExp _seriesYearNumberRegex = RegExp(
    r'\b([A-Za-z]{1,8})[-_/ ]*(20\d{2})[-_/ ]*([0-9]{1,10})\b',
    caseSensitive: false,
  );

  /// Series + number patterns in Romanian billing text:
  /// Examples:
  /// - Factura seria SL nr. 10492
  /// - Factura seria SL-2024 nr 10492
  /// - Seria: SL, Numar: 10492
  /// - Factura SL 10492
  /// - SOLO-10492 or SL-10492
  static final RegExp _explicitSeriesAndNumberRegex = RegExp(
    r'(?:factur[aă]\s+(?:fiscal[aă]\s+)?(?:seria\s+)?|seria\s*:?\s*)([A-Za-z]{1,8}(?:[-_/]20\d{2})?)[,\s\-_/]+(?:nr\.?|num[aă]rul|numar|no\.?)?\s*:?\s*#?([0-9]{1,10})\b',
    caseSensitive: false,
  );

  /// Standalone series-number tokens like SL-10492, SOLO-10492, SL10492, SL_10492 (excluding year-chained numbers)
  static final RegExp _tokenSeriesNumberRegex = RegExp(
    r'\b(SL|SOLO|FACT|INV|BILL|QUAL|AGR)[-_ ]*([0-9]{1,10})\b(?!\s*[-_/]\s*\d)',
    caseSensitive: false,
  );

  /// Factura #10492 or Factura nr. 10492 (without explicit series)
  static final RegExp _invoiceNumberOnlyRegex = RegExp(
    r'(?:factur[aă]\s+(?:fiscal[aă]\s+)?(?:nr\.?|num[aă]rul|numar|#)\s*:?\s*|#)([0-9]{2,10})\b',
    caseSensitive: false,
  );

  /// Amount with currency: "1500 RON", "1.500,00 lei", "350 EUR"
  static final RegExp _amountRegex = RegExp(
    r'(\d+(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\s*(RON|LEI|EUR|EURO|€|\$)\b',
    caseSensitive: false,
  );

  /// Date regex: "15.10.2024", "15/10/2024", "2024-10-15"
  static final RegExp _dateRegex = RegExp(
    r'\b(?:din\s+(?:data\s+de\s+)?)?(\d{1,2})[./\-](\d{1,2})[./\-](\d{4})\b|\b(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})\b',
    caseSensitive: false,
  );

  /// Parses arbitrary text (URLs, messages, or invoice identifiers) into [ParsedInvoiceResult].
  static ParsedInvoiceResult parse(
    String input, {
    String defaultSeries = 'SOLO',
  }) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return const ParsedInvoiceResult(rawInput: '');
    }

    // 1. Extract URL (if any)
    String? extractedUrl = _extractUrl(cleanInput);

    // 2. Identify platform
    InvoicePlatform platform = _detectPlatform(cleanInput, extractedUrl);

    // 3. Extract Series & Number
    String? extractedSeries;
    String? extractedNumber;
    bool hasExplicitSeries = false;

    // First check for series with year, e.g. SL-2024-10492
    final yearSeriesMatch = _seriesYearNumberRegex.firstMatch(cleanInput);
    if (yearSeriesMatch != null) {
      extractedSeries = '${yearSeriesMatch.group(1)?.toUpperCase()}-${yearSeriesMatch.group(2)}';
      extractedNumber = yearSeriesMatch.group(3);
      hasExplicitSeries = true;
    }

    // Check text for explicit series & number
    if (extractedNumber == null) {
      final explicitMatch = _explicitSeriesAndNumberRegex.firstMatch(cleanInput);
      if (explicitMatch != null) {
        extractedSeries = explicitMatch.group(1)?.toUpperCase();
        extractedNumber = explicitMatch.group(2);
        hasExplicitSeries = true;
      }
    }

    // If not found, try token series like SL-10492 or SOLO-10492
    if (extractedNumber == null) {
      final tokenMatch = _tokenSeriesNumberRegex.firstMatch(cleanInput);
      if (tokenMatch != null) {
        extractedSeries = tokenMatch.group(1)?.toUpperCase();
        extractedNumber = tokenMatch.group(2);
        hasExplicitSeries = true;
      }
    }

    // If still not found, try to extract series and number from the URL itself!
    if (extractedNumber == null && extractedUrl != null) {
      final fromUrl = _extractFromUrl(extractedUrl);
      if (fromUrl != null) {
        extractedSeries = fromUrl['series'];
        extractedNumber = fromUrl['number'];
        hasExplicitSeries = fromUrl['hasExplicitSeries'] == 'true';
        if (fromUrl['platform'] == 'solo') {
          platform = InvoicePlatform.solo;
        }
      }
    }

    // If still not found, try "Factura nr. 10492"
    if (extractedNumber == null) {
      final numberOnlyMatch = _invoiceNumberOnlyRegex.firstMatch(cleanInput);
      if (numberOnlyMatch != null) {
        extractedNumber = numberOnlyMatch.group(1);
        extractedSeries = platform == InvoicePlatform.solo ? 'SL' : defaultSeries;
        hasExplicitSeries = false;
      }
    }

    // If still not found, try to extract series and number from the URL itself!
    if (extractedNumber == null && extractedUrl != null) {
      final fromUrl = _extractFromUrl(extractedUrl);
      if (fromUrl != null) {
        extractedSeries = fromUrl['series'];
        extractedNumber = fromUrl['number'];
        hasExplicitSeries = fromUrl['hasExplicitSeries'] == 'true';
        if (fromUrl['platform'] == 'solo') {
          platform = InvoicePlatform.solo;
        }
      }
    }

    // If pure number entered (e.g. "10492")
    if (extractedNumber == null && RegExp(r'^\d{2,10}$').hasMatch(cleanInput)) {
      extractedNumber = cleanInput;
      extractedSeries = defaultSeries;
      hasExplicitSeries = false;
    }

    // Normalize invoice number format (e.g. SL-10492 or SOLO-10492)
    String? normalizedInvoiceNumber;
    if (extractedNumber != null && extractedNumber.isNotEmpty) {
      final s = (extractedSeries != null && extractedSeries.isNotEmpty)
          ? extractedSeries
          : (platform == InvoicePlatform.solo ? 'SL' : defaultSeries);
      normalizedInvoiceNumber = normalizeInvoiceNumber(s, extractedNumber);
    }

    // 4. Extract Amount & Currency
    double? amount;
    String? currency;
    final amountMatch = _amountRegex.firstMatch(cleanInput);
    if (amountMatch != null) {
      final rawAmountStr = amountMatch.group(1);
      final rawCurrency = amountMatch.group(2)?.toUpperCase();

      if (rawAmountStr != null) {
        // Romanian number formatting: 1.500,50 -> 1500.50
        String sanitized = rawAmountStr.replaceAll('.', '').replaceAll(',', '.');
        amount = double.tryParse(sanitized);
      }

      if (rawCurrency != null) {
        if (rawCurrency == 'LEI') {
          currency = 'RON';
        } else if (rawCurrency == 'EURO' || rawCurrency == '€') {
          currency = 'EUR';
        } else if (rawCurrency == r'$') {
          currency = 'USD';
        } else {
          currency = rawCurrency;
        }
      }
    }

    // 5. Extract Date
    DateTime? issueDate;
    final dateMatch = _dateRegex.firstMatch(cleanInput);
    if (dateMatch != null) {
      try {
        if (dateMatch.group(1) != null) {
          // DD.MM.YYYY
          final day = int.parse(dateMatch.group(1)!);
          final month = int.parse(dateMatch.group(2)!);
          final year = int.parse(dateMatch.group(3)!);
          issueDate = DateTime(year, month, day);
        } else if (dateMatch.group(4) != null) {
          // YYYY-MM-DD
          final year = int.parse(dateMatch.group(4)!);
          final month = int.parse(dateMatch.group(5)!);
          final day = int.parse(dateMatch.group(6)!);
          issueDate = DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return ParsedInvoiceResult(
      invoiceNumber: normalizedInvoiceNumber,
      invoiceUrl: extractedUrl,
      series: extractedSeries,
      number: extractedNumber,
      amount: amount,
      currency: currency,
      issueDate: issueDate,
      platform: platform,
      rawInput: cleanInput,
      hasExplicitSeries: hasExplicitSeries,
    );
  }

  /// Extracts the most relevant invoice URL from input.
  static String? _extractUrl(String input) {
    final matches = _urlRegex.allMatches(input);
    if (matches.isEmpty) return null;

    final urls = matches.map((m) => m.group(0)!).toList();

    // Priority 1: SOLO domain URL
    for (final url in urls) {
      if (url.toLowerCase().contains('solo.ro')) {
        return _cleanUrl(url);
      }
    }

    // Priority 2: PDF link or invoices path
    for (final url in urls) {
      final lower = url.toLowerCase();
      if (lower.endsWith('.pdf') || lower.contains('invoice') || lower.contains('factur')) {
        return _cleanUrl(url);
      }
    }

    // Fallback: First URL
    return _cleanUrl(urls.first);
  }

  /// Cleans trailing punctuation from extracted URL (e.g. parentheses, dots at end of sentence).
  static String _cleanUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('.') ||
        cleaned.endsWith(',') ||
        cleaned.endsWith(';') ||
        cleaned.endsWith(')') ||
        cleaned.endsWith('>')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Detects the invoicing platform from text and URL.
  static InvoicePlatform _detectPlatform(String text, String? url) {
    final lowerText = text.toLowerCase();
    final lowerUrl = url?.toLowerCase() ?? '';

    if (lowerUrl.contains('solo.ro') ||
        lowerText.contains('solo.ro') ||
        RegExp(r'\b(solo|sl)\b', caseSensitive: false).hasMatch(text)) {
      return InvoicePlatform.solo;
    }
    if (lowerUrl.contains('smartbill.ro') || lowerText.contains('smartbill')) {
      return InvoicePlatform.smartbill;
    }
    if (lowerUrl.contains('oblio.eu') ||
        lowerUrl.contains('oblio.ro') ||
        lowerText.contains('oblio')) {
      return InvoicePlatform.oblio;
    }
    if (lowerUrl.contains('fgo.ro') || lowerText.contains('fgo')) {
      return InvoicePlatform.fgo;
    }
    return InvoicePlatform.generic;
  }

  /// Extracts series, number, and metadata from URL structure:
  /// Examples:
  /// - https://app.solo.ro/invoices/SL-10492
  /// - https://app.solo.ro/invoices/10492
  /// - https://solo.ro/i/10492
  /// - https://solo.ro/factura/SL-2024-10492
  /// - https://app.solo.ro/facturi/view/SL10492
  /// - https://example.com/storage/factura_SL_10492.pdf
  static Map<String, String>? _extractFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final isSoloHost = uri.host.toLowerCase().contains('solo.ro');

      // Check query parameters first
      if (uri.queryParameters.isNotEmpty) {
        final qp = uri.queryParameters;
        final qNumber = qp['number'] ?? qp['nr'] ?? qp['numar'] ?? qp['invoice'];
        final qSeries = qp['series'] ?? qp['serie'];
        if (qNumber != null && RegExp(r'^\d+$').hasMatch(qNumber)) {
          return {
            'series': (qSeries ?? (isSoloHost ? 'SL' : 'SOLO')).toUpperCase(),
            'number': qNumber,
            'hasExplicitSeries': (qSeries != null).toString(),
            'platform': isSoloHost ? 'solo' : 'generic',
          };
        }
      }

      // Check path segments
      for (final segment in uri.pathSegments.reversed) {
        // e.g. "SL-10492" or "SL-2024-10492" or "SOLO-10492"
        final segMatch = RegExp(
          r'^([A-Za-z]{1,8}(?:-\d{4})?)[-_]?([0-9]{1,10})(?:\.pdf)?$',
          caseSensitive: false,
        ).firstMatch(segment);

        if (segMatch != null) {
          return {
            'series': segMatch.group(1)!.toUpperCase(),
            'number': segMatch.group(2)!,
            'hasExplicitSeries': 'true',
            'platform': isSoloHost ? 'solo' : 'generic',
          };
        }

        // Pure numeric segment: e.g. "/invoices/10492" or "/i/10492"
        final pureNum = segment.replaceAll('.pdf', '');
        if (RegExp(r'^\d{2,10}$').hasMatch(pureNum)) {
          return {
            'series': isSoloHost ? 'SL' : 'SOLO',
            'number': pureNum,
            'hasExplicitSeries': 'false',
            'platform': isSoloHost ? 'solo' : 'generic',
          };
        }

        // Segment containing "factura_SL_10492"
        final fileMatch = RegExp(
          r'factur[aă]?[_\-]?([A-Za-z]{1,8})[_\-]?([0-9]{1,10})',
          caseSensitive: false,
        ).firstMatch(segment);
        if (fileMatch != null) {
          return {
            'series': fileMatch.group(1)!.toUpperCase(),
            'number': fileMatch.group(2)!,
            'hasExplicitSeries': 'true',
            'platform': isSoloHost ? 'solo' : 'generic',
          };
        }
      }
    } catch (_) {}

    return null;
  }

  /// Normalizes series and number into a standard canonical format.
  /// E.g.: ("SL", "10492") -> "SL-10492"
  /// E.g.: ("SOLO", "10492") -> "SOLO-10492"
  /// E.g.: ("SL-2024", "10492") -> "SL-2024-10492"
  static String normalizeInvoiceNumber(String series, String number) {
    final cleanSeries = series.trim().toUpperCase().replaceAll(' ', '-');
    final cleanNumber = number.trim();

    if (cleanSeries.isEmpty) {
      return cleanNumber;
    }
    if (cleanSeries.endsWith('-')) {
      return '$cleanSeries$cleanNumber';
    }
    return '$cleanSeries-$cleanNumber';
  }

  /// Quick check whether a string likely contains an invoice URL or invoice series/number.
  static bool isLikelyInvoiceLinkOrText(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    if (lower.contains('solo.ro') ||
        lower.contains('invoices') ||
        lower.contains('factur') ||
        lower.contains('.pdf')) {
      return true;
    }
    return _explicitSeriesAndNumberRegex.hasMatch(text) ||
        _tokenSeriesNumberRegex.hasMatch(text) ||
        _invoiceNumberOnlyRegex.hasMatch(text);
  }
}
