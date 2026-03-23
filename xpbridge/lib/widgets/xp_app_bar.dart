import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'xp_card.dart';

class XPAppBar extends StatelessWidget implements PreferredSizeWidget {
  const XPAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

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
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.goNamed('studentDashboard'),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Icon(icon, color: foregroundColor, size: 20),
        ),
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
    return XPCard(
      radius: AppTheme.cornerRadiusLarge,
      padding: const EdgeInsets.all(AppSpacing.xl),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            letterSpacing: 1.2,
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
    final color = backgroundColor ?? AppTheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class XPBottomActionBar extends StatelessWidget {
  const XPBottomActionBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadiusLarge),
        ),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
