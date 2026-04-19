// Conditional export: on web we use `package:web` to mutate the URL;
// on other platforms this is a no-op.
export 'web_url_stub.dart' if (dart.library.js_interop) 'web_url_web.dart';
