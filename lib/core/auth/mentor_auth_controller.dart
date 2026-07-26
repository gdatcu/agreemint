import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'mentor_auth_controller.g.dart';

@riverpod
class MentorAuthController extends _$MentorAuthController {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  Future<bool> build() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    // Listen for auth state changes (login, logout, token refresh)
    _authSubscription?.cancel();
    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      final isAuthenticated = data.session != null;
      state = AsyncValue.data(isAuthenticated);
    });

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return session != null;
  }

  /// Authenticates the mentor with email and password via Supabase Auth.
  Future<String?> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.session != null) {
        state = const AsyncValue.data(true);
        return null; // Success, no error
      }
      return 'Authentication failed. Please check your credentials.';
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('Login error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Logs out the mentor and revokes the Supabase session.
  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      state = const AsyncValue.data(false);
    } catch (e) {
      debugPrint('Logout error: $e');
      state = const AsyncValue.data(false);
    }
  }
}
