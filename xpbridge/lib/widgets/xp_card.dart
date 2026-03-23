import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'xp_premium.dart';

class XPCard extends StatelessWidget {
  const XPCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.elevated = false,
    this.bordered = false,
    this.backgroundColor,
    this.radius,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool elevated;
  final bool bordered;
  final Color? backgroundColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      onTap: onTap,
      padding: padding,
      borderRadius: radius ?? AppTheme.cornerRadiusLarge,
      backgroundColor: backgroundColor ?? AppTheme.glassStrong,
      borderColor: bordered
          ? AppTheme.primary.withValues(alpha: 0.14)
          : AppTheme.glassBorder,
      shadow: elevated ? AppTheme.elevatedShadow : AppTheme.glassShadow,
      child: child,
    );
  }
}

class XPSection extends StatelessWidget {
  const XPSection({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      padding: padding,
      backgroundColor: backgroundColor ?? AppTheme.glassStrong,
      elevated: true,
      radius: AppTheme.cornerRadiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || action != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          child,
        ],
      ),
    );
  }
}

class XPContainer extends StatelessWidget {
  const XPContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.cornerRadiusSmall,
        ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class XPBadge extends StatelessWidget {
  const XPBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final background = color ?? AppTheme.surface.withValues(alpha: 0.72);
    final foreground = textColor ?? AppTheme.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class XPProgressBar extends StatelessWidget {
  const XPProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.showLabel = false,
  });

  final double progress;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: height,
            backgroundColor: AppTheme.primarySoft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
