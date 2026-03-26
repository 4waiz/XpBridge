import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';

class AdminPreviewScreen extends StatelessWidget {
  const AdminPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return XPPageScaffold(
      title: 'Preview modes',
      subtitle: 'Open the app as a demo student or startup.',
      showBack: true,
      onBack: () {
        appState.exitAdminPreview();
        context.goNamed('admin');
      },
      compact: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.page,
        ),
        children: [
          XPSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'These use bundled demo data and do not modify your real account.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - AppSpacing.lg) / 2;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  SizedBox(
                    width: width,
                    child: _PreviewCard(
                      icon: Icons.school_rounded,
                      title: 'Student preview',
                      subtitle: 'See discovery, applications, and profile as a demo student.',
                      actionLabel: 'Open student view',
                      onPressed: () {
                        appState.enterAdminPreview(UserRole.student);
                        context.goNamed('studentDashboard');
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _PreviewCard(
                      icon: Icons.rocket_launch_rounded,
                      title: 'Startup preview',
                      subtitle: 'See applicants, talent browsing, and startup profile as a demo startup.',
                      actionLabel: 'Open startup view',
                      onPressed: () {
                        appState.enterAdminPreview(UserRole.startup);
                        context.goNamed('startupDashboard');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, color: AppTheme.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xl),
          XPButton(
            label: actionLabel,
            icon: Icons.arrow_forward_rounded,
            size: XPButtonSize.medium,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
