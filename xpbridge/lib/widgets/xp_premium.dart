import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XPScene extends StatelessWidget {
  const XPScene({super.key, required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          Positioned(
            top: compact ? -100 : -160,
            left: -80,
            right: -40,
            height: compact ? 280 : 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryDeep,
                    AppTheme.primaryDark,
                    AppTheme.primary.withValues(alpha: 0.88),
                    AppTheme.primaryLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(220),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.26),
                    blurRadius: 120,
                    spreadRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: compact ? 160 : 240,
            right: -90,
            width: 220,
            height: 220,
            child: _GlowOrb(color: AppTheme.primary.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            width: 220,
            height: 220,
            child: _GlowOrb(
              color: AppTheme.primaryDark.withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.34, 0.72, 1],
                  colors: [
                    Colors.transparent,
                    AppTheme.background.withValues(alpha: 0.24),
                    AppTheme.background.withValues(alpha: 0.88),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class XPGlassPanel extends StatelessWidget {
  const XPGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.shadow,
    this.blurSigma = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      borderRadius ?? AppTheme.cornerRadiusLarge,
    );
    final panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.glass,
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? AppTheme.glassBorder,
              width: 1,
            ),
            boxShadow: shadow ?? AppTheme.glassShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: panel),
    );
  }
}

class XPPremiumSearchBar extends StatelessWidget {
  const XPPremiumSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderRadius: AppTheme.pillRadius,
      backgroundColor: AppTheme.glassStrong,
      shadow: AppTheme.floatingShadow,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              boxShadow: AppTheme.softGlowShadow,
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppTheme.surface,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hintText,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class XPPremiumSheet extends StatelessWidget {
  const XPPremiumSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: XPGlassPanel(
        padding: padding,
        backgroundColor: AppTheme.sheetBackground,
        borderRadius: 34,
        blurSigma: 26,
        shadow: AppTheme.modalShadow,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.text.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppTheme.text),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (title != null || subtitle != null) ...[
                const SizedBox(height: AppSpacing.xl),
              ],
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class XPOpportunityCard extends StatelessWidget {
  const XPOpportunityCard({
    super.key,
    required this.company,
    required this.title,
    required this.description,
    required this.meta,
    required this.skills,
    this.matchLabel,
    this.primaryLabel = 'View role',
    this.onTap,
    this.onPrimaryTap,
    this.featured = false,
  });

  final String company;
  final String title;
  final String description;
  final List<String> meta;
  final List<Widget> skills;
  final String? matchLabel;
  final String primaryLabel;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final textColor = featured ? AppTheme.surface : AppTheme.text;
    final secondaryColor = featured
        ? AppTheme.surface.withValues(alpha: 0.76)
        : AppTheme.textSecondary;
    final panel = XPGlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: featured ? 34 : 30,
      backgroundColor: featured
          ? AppTheme.primaryDeep.withValues(alpha: 0.82)
          : AppTheme.surface.withValues(alpha: 0.78),
      gradient: featured
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryDeep,
                AppTheme.primaryDark,
                AppTheme.primary.withValues(alpha: 0.82),
              ],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface.withValues(alpha: 0.88),
                AppTheme.surface.withValues(alpha: 0.72),
              ],
            ),
      borderColor: featured
          ? AppTheme.surface.withValues(alpha: 0.2)
          : AppTheme.primary.withValues(alpha: 0.16),
      shadow: featured ? AppTheme.heroCardShadow : AppTheme.glassShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: secondaryColor,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: textColor,
                            fontSize: featured ? 30 : 24,
                          ),
                    ),
                  ],
                ),
              ),
              if (matchLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: featured
                        ? AppTheme.surface.withValues(alpha: 0.12)
                        : AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    border: Border.all(
                      color: featured
                          ? AppTheme.surface.withValues(alpha: 0.16)
                          : AppTheme.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    matchLabel!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: textColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: meta.map((item) {
              return _MetaPill(
                label: item,
                textColor: textColor,
                backgroundColor: featured
                    ? AppTheme.surface.withValues(alpha: 0.1)
                    : AppTheme.surface.withValues(alpha: 0.7),
                borderColor: featured
                    ? AppTheme.surface.withValues(alpha: 0.14)
                    : AppTheme.primary.withValues(alpha: 0.12),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: secondaryColor,
              height: 1.55,
            ),
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: skills,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  featured
                      ? 'Curated by XPBridge AI'
                      : 'Recommended based on fit',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: secondaryColor),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _MiniActionButton(
                label: primaryLabel,
                onTap: onPrimaryTap ?? onTap,
                bright: featured,
              ),
            ],
          ),
        ],
      ),
    );

    return panel;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: textColor),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.onTap,
    required this.bright,
  });

  final String label;
  final VoidCallback? onTap;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: bright
              ? AppTheme.whiteGlowGradient
              : AppTheme.primaryGlowGradient,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          boxShadow: bright ? AppTheme.softShadow : AppTheme.softGlowShadow,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: bright ? AppTheme.primaryDeep : AppTheme.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class XPApplicationStatusCard extends StatelessWidget {
  const XPApplicationStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.progress,
    required this.summary,
    this.trailing,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final double progress;
  final String summary;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              backgroundColor: AppTheme.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.lg),
            trailing!,
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.lg),
            footer!,
          ],
        ],
      ),
    );
  }
}

class XPChatComposer extends StatelessWidget {
  const XPChatComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      borderRadius: 30,
      backgroundColor: AppTheme.sheetBackground,
      shadow: AppTheme.modalShadow,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: hintText,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedOpacity(
              opacity: isLoading ? 0.7 : 1,
              duration: const Duration(milliseconds: 160),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGlowGradient,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  boxShadow: AppTheme.softGlowShadow,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.surface,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppTheme.surface,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
