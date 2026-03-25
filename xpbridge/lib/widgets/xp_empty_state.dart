import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'xp_button.dart';
import 'xp_card.dart';

class XPEmptyState extends StatelessWidget {
  const XPEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return XPSection(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softGlowShadow,
            ),
            child: Icon(icon, color: AppTheme.surface, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            XPButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
