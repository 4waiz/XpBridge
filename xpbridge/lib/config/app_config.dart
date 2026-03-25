class AppConfig {
  AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.storageBucket,
    required this.adminEmails,
    this.geminiApiKey,
    this.sentryDsn,
    this.analyticsKey,
  });

  static late final AppConfig instance;

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String? geminiApiKey;
  final String storageBucket;
  final Set<String> adminEmails;
  final String? sentryDsn;
  final String? analyticsKey;

  bool get aiFeaturesEnabled => (geminiApiKey ?? '').trim().isNotEmpty;

  bool isAdminEmail(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }

  static AppConfig fromEnvironment(Map<String, String> environment) {
    final supabaseUrl = _requiredValue(environment, 'SUPABASE_URL');
    final supabaseAnonKey = _requiredValue(environment, 'SUPABASE_ANON_KEY');
    final storageBucket = environment['STORAGE_BUCKET']?.trim().isNotEmpty ==
            true
        ? environment['STORAGE_BUCKET']!.trim()
        : 'xpbridge-assets';
    final adminEmails = environment['ADMIN_EMAILS']
            ?.split(',')
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet() ??
        <String>{};

    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      geminiApiKey: _optionalValue(environment, 'GEMINI_API_KEY'),
      storageBucket: storageBucket,
      adminEmails: adminEmails,
      sentryDsn: _optionalValue(environment, 'SENTRY_DSN'),
      analyticsKey: _optionalValue(environment, 'ANALYTICS_KEY'),
    );
  }

  static String _requiredValue(Map<String, String> environment, String key) {
    final value = environment[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }

  static String? _optionalValue(Map<String, String> environment, String key) {
    final value = environment[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
