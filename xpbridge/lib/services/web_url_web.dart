import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Replaces the browser URL in place without triggering a navigation.
/// Mirrors `window.history.replaceState({}, document.title, newUrl)`.
void replaceBrowserUrl(String newUrl) {
  try {
    web.window.history.replaceState(
      null as JSAny?,
      web.document.title,
      newUrl,
    );
  } catch (_) {
    // Non-fatal: a stale browser or iframe sandbox can reject replaceState.
    // The app will still function; the URL will just retain the query.
  }
}
