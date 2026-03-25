import 'dart:convert';
import 'dart:typed_data';

/// Legacy helper retained for compatibility with older screens.
class LogoImageService {
  static const storageKey = 'startup_logo_base64';

  static String encode(Uint8List data) => base64Encode(data);

  static Uint8List? decode(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}
