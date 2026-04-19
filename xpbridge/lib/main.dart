import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xpbridge/app.dart';
import 'package:xpbridge/config/env_loader.dart';
import 'package:xpbridge/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await EnvLoader.load();

  // Snapshot the OAuth callback URL BEFORE Supabase.initialize runs.
  // supabase_flutter's built-in `detectSessionInUri` listener can strip
  // the `?code=` from `Uri.base` during initialization (via
  // window.history.replaceState). If we wait until AFTER initialize to
  // look for the code, we may find nothing — leaving the user in a
  // signed-out state on `/login` even though Google sent us a valid code.
  final Uri? pendingCallback = SupabaseService.capturePendingOAuthCallback();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  // If supabase_flutter's auto-detect already restored a session, this
  // returns fast. Otherwise we manually exchange the captured URL.
  await SupabaseService.ensureSessionFromPendingCallback(pendingCallback);

  // Fully hydrate AppState BEFORE runApp so the router never paints
  // `/login` while the callback is still mid-flight. By the first frame,
  // `isInitialized` and `isLoggedIn` already reflect the real auth state,
  // and the router redirects straight to the correct post-login route.
  final appState = AppState();
  await appState.initialize();

  runApp(XPBridgeApp(appState: appState));
}
