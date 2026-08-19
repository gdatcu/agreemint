import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business_settings_model.dart';
import '../services/business_settings_service.dart';

final businessSettingsControllerProvider =
    AsyncNotifierProvider<BusinessSettingsController, BusinessSettingsModel>(
        BusinessSettingsController.new);

class BusinessSettingsController extends AsyncNotifier<BusinessSettingsModel> {
  @override
  Future<BusinessSettingsModel> build() async {
    return await BusinessSettingsService.loadSettings();
  }

  /// Updates business settings and persists to SharedPreferences.
  Future<void> updateSettings(BusinessSettingsModel updated) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await BusinessSettingsService.saveSettings(updated);
      return updated;
    });
  }

  /// Resets business settings back to default presets.
  Future<void> resetToDefaults() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await BusinessSettingsService.clearSettings();
      return const BusinessSettingsModel();
    });
  }
}
