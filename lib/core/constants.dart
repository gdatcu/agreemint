/// App-wide constants including Supabase configurations and Web Portal URLs.
///
/// Supabase credentials are loaded from environment variables (--dart-define)
/// with fallback values provided for seamless local development.
class AppConstants {
  static const String _envSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String _envSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String _defaultSupabaseUrl =
      'https://rlyfzvciozjkbouvnzft.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJseWZ6dmNpb3pqa2JvdXZuemZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MTMzNDIsImV4cCI6MjEwMDQ4OTM0Mn0.BCbiz3Jdx-dV0WBzvrItWegiydPLLWsgBxzaToTFb6Y';

  static String get supabaseUrl =>
      _envSupabaseUrl.trim().isNotEmpty ? _envSupabaseUrl : _defaultSupabaseUrl;

  static String get supabaseAnonKey =>
      _envSupabaseAnonKey.trim().isNotEmpty
          ? _envSupabaseAnonKey
          : _defaultSupabaseAnonKey;

  /// Base web domain URL used for client contract signing portal links.
  static const String clientPortalBaseUrl =
      'https://apps.qualiadept.eu/agreemint/#/sign/';
}
