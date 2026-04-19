import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xpbridge/app.dart';
import 'package:xpbridge/config/env_loader.dart';
import 'package:xpbridge/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await EnvLoader.load();

  // Snapshot the OAuth callback URL BEFORE Supabase.initialize runs.
  // supabase_flutter's built-in detectSessionInUri can strip ?code= from
  // Uri.base during initialization (via window.history.replaceState). If
  // we wait until after initialize, the query is gone.
  final Uri? pendingCallback = SupabaseService.capturePendingOAuthCallback();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  // Exchange the code, always clean the URL (success OR failure), and never
  // let an uncaught exception escape and leave Flutter unmounted. The splash
  // rendered without an app attached would be worse than a clear failure.
  try {
    debugPrint(
      '[bootstrap] pendingCallback=${pendingCallback != null ? 'present' : 'none'}',
    );
    await SupabaseService.ensureSessionFromPendingCallback(pendingCallback);
  } catch (error, stack) {
    debugPrint('[bootstrap] ensureSession threw: $error\n$stack');
  }

  // If the user previously kicked off a Google-reauth account deletion and
  // has just returned with a fresh session, finish the job BEFORE the
  // router can paint any authenticated screen. On success, `currentUser`
  // becomes null and appState.initialize() naturally routes to /login,
  // where a one-shot success message is picked up and shown.
  try {
    await SupabaseService.executePendingAccountDeletion();
  } catch (error, stack) {
    debugPrint('[bootstrap] pending deletion threw: $error\n$stack');
  }

  // Fully hydrate AppState BEFORE runApp so the router never paints
  // /login while the callback is still mid-flight. By the first frame,
  // isInitialized and isLoggedIn already reflect the real auth state,
  // and the router redirects straight to the correct post-login route.
  final appState = AppState();
  try {
    await appState.initialize();
  } catch (error, stack) {
    // AppState.refreshSession already catches internally and flips
    // `_isInitialized = true` in its finally block, so this is pure
    // defence-in-depth. If we somehow land here, fire-and-forget a
    // second init to release the splash gate, then proceed. Pure defense.
    debugPrint('[bootstrap] appState.initialize threw: $error\n$stack');
  }

  runApp(XPBridgeApp(appState: appState));
}
