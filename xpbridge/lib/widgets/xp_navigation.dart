import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon ?? item.icon : item.icon,
                            size: 20,
                            color: isActive ? AppTheme.text : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isActive ? AppTheme.text : AppTheme.textMuted,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
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
