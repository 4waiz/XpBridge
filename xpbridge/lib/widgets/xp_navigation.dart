import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'xp_premium.dart';

class XPBottomNavBar extends StatelessWidget {
  const XPBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<XPBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: XPGlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          borderRadius: 32,
          backgroundColor: AppTheme.sheetBackground,
          blurSigma: 26,
          shadow: AppTheme.modalShadow,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? AppTheme.primaryGlowGradient
                            : null,
                        color: isActive ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cornerRadiusSmall,
                        ),
                        boxShadow: isActive ? AppTheme.softGlowShadow : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon ?? item.icon : item.icon,
                            size: 20,
                            color: isActive
                                ? AppTheme.surface
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isActive
                                      ? AppTheme.surface
                                      : AppTheme.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class XPBottomNavItem {
  const XPBottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
}
