import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/social_links.dart';
import '../theme/app_theme.dart';

/// "Follow us" footer used on the auth and profile screens. Three tappable
/// links that open the XPBridge social profiles in an external browser/app —
/// styled to match the existing Privacy/Terms footer links.
class SocialLinksRow extends StatelessWidget {
  const SocialLinksRow({super.key, this.showCaption = true});

  final bool showCaption;

  static const _links = <(String, IconData, String)>[
    ('Instagram', Icons.camera_alt_outlined, SocialLinks.instagram),
    ('X', Icons.alternate_email_rounded, SocialLinks.x),
    ('LinkedIn', Icons.work_outline_rounded, SocialLinks.linkedIn),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showCaption) ...[
          Text(
            'Follow us',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            for (final (label, icon, url) in _links)
              TextButton.icon(
                onPressed: () => _open(url),
                icon: Icon(icon, size: 16, color: AppTheme.primaryDark),
                label: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
