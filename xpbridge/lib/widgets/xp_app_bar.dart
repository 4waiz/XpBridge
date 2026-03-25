import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'xp_premium.dart';

class XPAppBar extends StatelessWidget implements PreferredSizeWidget {
  const XPAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (showBack) ...[
              XPHeaderButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack ??
                    () => context.canPop()
                        ? context.pop()
                        : context.go('/intro'),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(92);
}

class XPHeaderButton extends StatelessWidget {
  const XPHeaderButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.foregroundColor = AppTheme.text,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.cornerRadiusSmall,
      backgroundColor: backgroundColor ?? AppTheme.glassStrong,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, color: foregroundColor, size: 20),
      ),
    );
  }
}

class XPDashboardAppBar extends StatelessWidget {
  const XPDashboardAppBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.leading,
    this.trailing,
    this.bottom,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: 34,
      backgroundColor: AppTheme.surface.withValues(alpha: 0.12),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.surface.withValues(alpha: 0.18),
          AppTheme.surface.withValues(alpha: 0.08),
        ],
      ),
      borderColor: AppTheme.surface.withValues(alpha: 0.2),
      shadow: AppTheme.heroCardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: AppTheme.surface.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: AppTheme.surface, fontSize: 42),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.surface.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.lg),
            bottom!,
          ],
        ],
      ),
    );
  }
}

class XPAvatar extends StatelessWidget {
  const XPAvatar({
    super.key,
    required this.initial,
    this.size = 56,
    this.backgroundColor,
  });

  final String initial;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface.withValues(alpha: 0.94),
            backgroundColor ?? AppTheme.primary.withValues(alpha: 0.74),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.38),
        border: Border.all(color: AppTheme.surface.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class XPBottomActionBar extends StatelessWidget {
  const XPBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: XPGlassPanel(
          padding: const EdgeInsets.all(AppSpacing.sm),
          borderRadius: 32,
          backgroundColor: AppTheme.sheetBackground,
          shadow: AppTheme.modalShadow,
          child: child,
        ),
      ),
    );
  }
}
