import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<String> _informationCollected = [
    'Account details such as name and email',
    'Profile information such as skills, education, availability, and company details',
    'User-generated content such as applications, mission reflections, feedback, portfolio links, and uploaded files or images',
    'Usage data needed to operate the app and improve reliability',
    'AI interaction data when users use AI-powered features',
  ];

  static const List<String> _informationUse = [
    'To create and manage user accounts',
    'To match students and startups',
    'To support missions, applications, feedback, and verified proof-of-work',
    'To provide AI-assisted guidance and matching features',
    'To maintain app security, moderation, and service performance',
  ];

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'XPBridge Privacy Policy',
      color: AppTheme.primaryDeep,
      child: XPPageScaffold(
        title: 'XPBridge Privacy Policy',
        showBack: true,
        onBack: () => _handleBack(context),
        body: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPSection(
                      backgroundColor: AppTheme.sheetBackground,
                      child: Text(
                        'XPBridge is a learning-first platform that connects students and startups through short missions, applications, feedback, and growth tracking.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppTheme.text),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Information we collect',
                      bullets: _informationCollected,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'How we use information',
                      bullets: _informationUse,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Data sharing',
                      paragraphs: [
                        'We only share data with service providers required to operate the platform, such as authentication, database, hosting, and AI processing providers.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Permissions',
                      paragraphs: [
                        'The app may request camera or photo library access for optional profile images, logos, or deliverables, file access for uploads, notifications for mission and feedback updates, and internet access for core functionality.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Data retention',
                      paragraphs: [
                        'We keep data only as long as needed to operate the service, support user accounts, and meet legal or security needs.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Children',
                      paragraphs: [
                        'XPBridge is not intended for children under 13.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _PolicySection(
                      title: 'Contact',
                      paragraphs: [
                        'For privacy questions, contact: xpbridge4u@gmail.com',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final appState = AppStateScope.of(context);
    if (appState.isLoggedIn) {
      context.go(appState.defaultAuthenticatedLocation);
      return;
    }

    context.go(appState.onboardingComplete ? '/login' : '/intro');
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary);

    return XPSection(
      title: title,
      backgroundColor: AppTheme.sheetBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < paragraphs.length; index++) ...[
            Text(paragraphs[index], style: bodyStyle),
            if (index < paragraphs.length - 1 || bullets.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
          ],
          for (var index = 0; index < bullets.length; index++) ...[
            _PolicyBullet(text: bullets[index]),
            if (index < bullets.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PolicyBullet extends StatelessWidget {
  const _PolicyBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
