import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_settings_model.dart';

class BusinessSettingsService {
  static const String _keySettings = 'agreemint_business_settings_v1';

  /// Loads stored business settings from SharedPreferences or Supabase DB.
  static Future<BusinessSettingsModel> loadSettings() async {
    BusinessSettingsModel? localModel;

    // 1. Try local SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySettings);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        localModel = BusinessSettingsModel.fromJson(map);
        if ((localModel.discordWebhookUrl != null && localModel.discordWebhookUrl!.isNotEmpty) ||
            (localModel.mentorNotificationEmail != null && localModel.mentorNotificationEmail!.isNotEmpty)) {
          return localModel;
        }
      }
    } catch (e) {
      debugPrint('Local settings load warning: $e');
    }

    // 2. Fallback to Supabase database `business_settings` table for external student signing devices
    try {
      final response = await Supabase.instance.client
          .from('business_settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final remoteModel = BusinessSettingsModel.fromJson(response);
        // Cache to local SharedPreferences
        await saveSettings(remoteModel);
        return remoteModel;
      }
    } catch (e) {
      debugPrint('Supabase business_settings fetch fallback warning: $e');
    }

    return localModel ?? const BusinessSettingsModel();
  }

  /// Saves updated business settings into SharedPreferences and Supabase DB.
  static Future<bool> saveSettings(BusinessSettingsModel settings) async {
    bool savedLocal = false;

    // 1. Save to local SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(settings.toJson());
      savedLocal = await prefs.setString(_keySettings, jsonStr);
    } catch (e) {
      debugPrint('Failed to save local settings: $e');
    }

    // 2. Sync to Supabase cloud DB so student signing links on external devices get mentor settings
    try {
      final map = settings.toJson();
      map['id'] = 1; // Single row business configuration table
      await Supabase.instance.client.from('business_settings').upsert(map);
    } catch (e) {
      debugPrint('Supabase business_settings upsert warning: $e');
    }

    return savedLocal;
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
