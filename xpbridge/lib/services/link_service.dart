import 'package:url_launcher/url_launcher.dart';

import 'supabase_service.dart';

class LinkService {
  const LinkService._();

  static Uri? normalize(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.tryParse(value);
    }
    return Uri.tryParse('https://$value');
  }

  static Future<void> openExternal(String? raw) async {
    final uri = normalize(raw);
    if (uri == null) {
      throw const XpServiceException('Invalid link.');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const XpServiceException('Could not open this link.');
    }
  }
}
