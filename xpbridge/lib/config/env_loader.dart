import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_config.dart';

class EnvLoader {
  const EnvLoader._();

  static Future<AppConfig> load() async {
    await dotenv.load(fileName: '.env');
    final config = AppConfig.fromEnvironment(dotenv.env);
    AppConfig.instance = config;
    return config;
  }
}
