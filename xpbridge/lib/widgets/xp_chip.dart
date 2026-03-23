import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XPChoiceChip extends StatelessWidget {
  const XPChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGlowGradient : null,
          color: selected ? null : AppTheme.glassStrong,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.18)
                : AppTheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: selected ? AppTheme.softGlowShadow : AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: selected ? AppTheme.surface : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppTheme.surface : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPFilterChip extends StatelessWidget {
  const XPFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGlowGradient : null,
          color: isSelected ? null : AppTheme.glassStrong,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.14)
                : AppTheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: isSelected ? AppTheme.softGlowShadow : AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.surface : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected ? AppTheme.surface : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPSkillTag extends StatelessWidget {
  const XPSkillTag({
    super.key,
    required this.label,
    this.isMatched = false,
    this.onTap,
  });

  final String label;
  final bool isMatched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: isMatched ? AppTheme.primaryGlowGradient : null,
        color: isMatched ? null : AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(
          color: isMatched
              ? AppTheme.primary.withValues(alpha: 0.14)
              : AppTheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatched) ...[
            const Icon(Icons.check_rounded, size: 15, color: AppTheme.surface),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isMatched ? AppTheme.surface : AppTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
