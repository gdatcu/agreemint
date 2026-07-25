import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'mentor_auth_controller.g.dart';

@riverpod
class MentorAuthController extends _$MentorAuthController {
  static const String _authKey = 'is_mentor_authenticated';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  /// Authenticates the mentor with a passcode/PIN.
  Future<bool> login(String passcode) async {
    // Accepts 'qualiadept' or '1234' or mentor master passcode
    final isValid = passcode.trim() == 'qualiadept' || passcode.trim() == '1234';
    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, true);
      state = const AsyncValue.data(true);
      return true;
    }
    return false;
  }

  /// Logs out the mentor and revokes access to management routes.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, false);
    state = const AsyncValue.data(false);
  }
}
