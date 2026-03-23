import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XPSectionTitle extends StatelessWidget {
  const XPSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.icon,
    this.subtitle,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
              boxShadow: AppTheme.softGlowShadow,
            ),
            child: Icon(icon, size: 18, color: AppTheme.surface),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionLabel!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTheme.primaryDeep),
            ),
          ),
      ],
    );
  }
}

class XPDivider extends StatelessWidget {
  const XPDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(height: AppSpacing.xxxl, thickness: 1);
    }

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label!, style: Theme.of(context).textTheme.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
