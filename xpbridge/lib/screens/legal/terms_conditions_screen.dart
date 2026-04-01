import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const List<String> _acceptableUse = [
    'Use the platform honestly and respectfully',
    'Keep account credentials private and secure',
    'Only submit truthful information in profiles, applications, and feedback',
    'Respect intellectual property and not copy or steal work from other users',
  ];

  static const List<String> _prohibited = [
    'Harassment, abuse, or discrimination of any kind',
    'Impersonation or misrepresentation of identity or qualifications',
    'Uploading malicious content, malware, or spam',
    'Attempting to access other users\u2019 accounts or private data',
    'Using the platform for any unlawful purpose',
  ];

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'XPBridge Terms & Conditions',
      color: AppTheme.primaryDeep,
      child: XPPageScaffold(
        title: 'Terms & Conditions',
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
                        'By creating an account or using XPBridge, you agree to these terms. Please read them carefully.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppTheme.text),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Overview',
                      paragraphs: [
                        'XPBridge is a learning-first platform that connects students with startups through short missions, applications, feedback, and growth tracking. These terms govern your access to and use of the platform.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Eligibility',
                      paragraphs: [
                        'You must be at least 13 years of age to use XPBridge. By registering, you confirm that the information you provide is accurate and that you are authorized to create an account.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Acceptable use',
                      paragraphs: [
                        'When using XPBridge, you agree to:',
                      ],
                      bullets: _acceptableUse,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Prohibited conduct',
                      paragraphs: [
                        'The following activities are strictly prohibited:',
                      ],
                      bullets: _prohibited,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'User content',
                      paragraphs: [
                        'You retain ownership of content you submit to XPBridge, such as profiles, applications, and feedback. By submitting content, you grant XPBridge a non-exclusive license to use, display, and store it as needed to operate the platform.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Account termination',
                      paragraphs: [
                        'We reserve the right to suspend or terminate accounts that violate these terms. You may delete your account at any time from your profile screen or by contacting xpbridge4u@gmail.com.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Disclaimer',
                      paragraphs: [
                        'XPBridge is provided on an "as is" basis. We do not guarantee the outcome of any mission, application, or connection made through the platform. XPBridge is not an employer and does not facilitate employment relationships.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Changes to these terms',
                      paragraphs: [
                        'We may update these terms from time to time. Continued use of the platform after changes constitutes acceptance of the updated terms.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _TermsSection(
                      title: 'Contact',
                      paragraphs: [
                        'For questions about these terms, contact: xpbridge4u@gmail.com',
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppTheme.textSecondary);

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
            _TermsBullet(text: bullets[index]),
            if (index < bullets.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _TermsBullet extends StatelessWidget {
  const _TermsBullet({required this.text});

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
