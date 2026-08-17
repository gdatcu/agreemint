import 'dart:convert';
import 'package:http/http.dart' as http;

class FrankfurterService {
  static const String _primaryUrl =
      'https://api.frankfurter.dev/v1/latest?base=EUR&symbols=RON';
  static const String _fallbackUrl =
      'https://api.frankfurter.app/latest?from=EUR&to=RON';

  static double? _cachedRate;
  static DateTime? _cacheTime;

  /// Fetches the latest EUR to RON exchange rate from Frankfurter API.
  static Future<double> getEurToRonRate() async {
    // Return cached rate if fetched within the last 1 hour
    if (_cachedRate != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!).inHours < 1) {
        return _cachedRate!;
      }
    }

    // Try primary endpoint
    try {
      final response = await http.get(Uri.parse(_primaryUrl)).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null && rates.containsKey('RON')) {
          final rate = (rates['RON'] as num).toDouble();
          _cachedRate = rate;
          _cacheTime = DateTime.now();
          return rate;
        }
      }
    } catch (_) {}

    // Try fallback endpoint
    try {
      final response = await http.get(Uri.parse(_fallbackUrl)).timeout(
            const Duration(seconds: 5),
          );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null && rates.containsKey('RON')) {
          final rate = (rates['RON'] as num).toDouble();
          _cachedRate = rate;
          _cacheTime = DateTime.now();
          return rate;
        }
      }
    } catch (_) {}

    // Fallback default BNR/ECB rate
    final fallbackRate = _cachedRate ?? 4.9750;
    _cachedRate = fallbackRate;
    _cacheTime = DateTime.now();
    return fallbackRate;
  }
}
