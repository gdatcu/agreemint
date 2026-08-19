import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_settings_model.dart';

class BusinessSettingsService {
  static const String _keySettings = 'agreemint_business_settings_v1';

  /// Loads stored business settings from SharedPreferences, or returns default instance.
  static Future<BusinessSettingsModel> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySettings);
      if (jsonStr == null || jsonStr.isEmpty) {
        return const BusinessSettingsModel();
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BusinessSettingsModel.fromJson(map);
    } catch (_) {
      return const BusinessSettingsModel();
    }
  }

  /// Saves updated business settings into SharedPreferences.
  static Future<bool> saveSettings(BusinessSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(settings.toJson());
      return await prefs.setString(_keySettings, jsonStr);
    } catch (_) {
      return false;
    }
  }

  /// Clears stored business settings back to default preset.
  static Future<bool> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keySettings);
    } catch (_) {
      return false;
    }
  }
}
