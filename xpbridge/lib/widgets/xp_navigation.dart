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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon ?? item.icon : item.icon,
                            size: 24,
                            color: isActive
                                ? AppTheme.primaryDark
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isActive
                                      ? AppTheme.primaryDark
                                      : AppTheme.textMuted,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
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
