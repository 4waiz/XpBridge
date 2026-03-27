class AppConfig {
  AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.storageBucket,
    required this.enableAiChat,
  });

  static late final AppConfig instance;
  static const Set<String> _allowedClientKeys = {
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'STORAGE_BUCKET',
    'ENABLE_AI_CHAT',
  };

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String storageBucket;
  final bool enableAiChat;

  bool get aiFeaturesEnabled => enableAiChat;

  static AppConfig fromEnvironment(Map<String, String> environment) {
    _validateClientEnvironment(environment);
    final supabaseUrl = _requiredValue(environment, 'SUPABASE_URL');
    final supabaseAnonKey = _requiredValue(environment, 'SUPABASE_ANON_KEY');
    final storageBucket =
        environment['STORAGE_BUCKET']?.trim().isNotEmpty == true
        ? environment['STORAGE_BUCKET']!.trim()
        : 'xpbridge-assets';

    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      storageBucket: storageBucket,
      enableAiChat: _boolValue(environment, 'ENABLE_AI_CHAT'),
    );
  }

  static void _validateClientEnvironment(Map<String, String> environment) {
    final unsupportedKeys = environment.keys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet()
        .difference(_allowedClientKeys);

    if (unsupportedKeys.isNotEmpty) {
      final keys = unsupportedKeys.toList()..sort();
      final allowed = _allowedClientKeys.toList()..sort();
      throw StateError(
        'Unsupported keys found in bundled client environment: '
        '${keys.join(', ')}. Only ${allowed.join(', ')} are allowed.',
      );
    }
  }

  static String _requiredValue(Map<String, String> environment, String key) {
    final value = environment[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }
    return value;
  }

  static bool _boolValue(Map<String, String> environment, String key) {
    final value = environment[key]?.trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes';
  }
}
