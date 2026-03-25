import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xpbridge/app.dart';
import 'package:xpbridge/config/env_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await EnvLoader.load();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  runApp(const XPBridgeApp());
}
