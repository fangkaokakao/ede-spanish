/// Environment configuration.
///
/// Only the Supabase URL and the publishable (anon) key ever ship in the
/// client. No service_role key, no AI provider key, no admin secret — those
/// live exclusively in Edge Function environment variables.
///
/// Supply via --dart-define. With no defines the app runs in `local` mode
/// against the embedded content pack, which is how you evaluate the slice
/// without a backend.
enum Flavor { dev, staging, prod }

/// Which repository set is wired up. The UI is identical either way; it depends
/// only on the interfaces in domain/repositories.dart.
enum DataSource {
  /// Embedded pack + Drift. No network. Grading mirrors the SQL rules and is
  /// explicitly development-only.
  local,

  /// Postgres + the RPCs covered by the 107-assertion pgTAP suite. The server
  /// is the authority on correctness, mastery and completion.
  supabase,
}

abstract final class Env {
  static const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _dataSource = String.fromEnvironment('DATA_SOURCE', defaultValue: 'local');

  static Flavor get flavor => switch (flavorName) {
        'prod' => Flavor.prod,
        'staging' => Flavor.staging,
        _ => Flavor.dev,
      };

  static DataSource get dataSource =>
      _dataSource == 'supabase' && isConfigured ? DataSource.supabase : DataSource.local;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Shown in a debug banner so it is never ambiguous which mode is running.
  static bool get isLocalMode => dataSource == DataSource.local;
}
