import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';
import '../../widgets/xp_button.dart';
import '../../services/supabase_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  static const List<String> _dataDeleted = [
    'Account details such as name and email',
    'Profile information such as skills, education, availability, and company details',
    'User-generated content such as applications, mission reflections, feedback, portfolio links, and uploaded files or images',
    'XP, levels, badges, and other account-linked progress data',
    'Startup/company profile data and related records linked to the account, where applicable',
  ];

  static const List<String> _dataRetained = [
    'Limited records that must be temporarily retained for security, fraud prevention, abuse prevention, or legal compliance',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await SupabaseService.client.from('account_deletion_requests').insert({
        'email': email,
        'note': _noteController.text.trim(),
      });
      setState(() {
        _successMessage = 'Your deletion request has been submitted. We will contact you at $email.';
        _emailController.clear();
        _noteController.clear();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to submit request. Please try again or email xpbridge4u@gmail.com.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'XPBridge Account Deletion',
      color: AppTheme.primaryDeep,
      child: XPPageScaffold(
        title: 'Account Deletion',
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
                        'Users can request deletion of their XPBridge account and associated personal data at any time.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _InfoSection(
                      title: 'How to delete your account',
                      paragraphs: [
                        'If you can still access your account, log in to XPBridge and use the in-app "Delete account" option from your profile/settings screen. This will send a 6-digit verification code to your email to confirm the request.',
                        'If you cannot access your account, you can use the form below or contact us at xpbridge4u@gmail.com using the email address linked to your account.',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _InfoSection(
                      title: 'What data is deleted',
                      bullets: _dataDeleted,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _InfoSection(
                      title: 'What may be retained',
                      bullets: _dataRetained,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPSection(
                      title: 'Request Account Deletion',
                      backgroundColor: AppTheme.sheetBackground,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_successMessage != null)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                              ),
                            ),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500),
                              ),
                            ),
                          Text(
                            'Email linked to your account',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'email@example.com',
                              filled: true,
                              fillColor: AppTheme.background,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Additional note (Optional)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              hintText: 'Reason for deletion or other details...',
                              filled: true,
                              fillColor: AppTheme.background,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: XPButton(
                              label: 'Submit Deletion Request',
                              onPressed: _isSubmitting ? null : _submitRequest,
                              loading: _isSubmitting,
                              backgroundColor: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _InfoSection(
                      title: 'Contact',
                      paragraphs: [
                        'For deletion support or inquiries, contact: xpbridge4u@gmail.com',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: XPOutlinedButton(
                        label: 'Back to Home',
                        expand: false,
                        onPressed: () => _handleBack(context),
                      ),
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

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary);

    return XPSection(
      title: title,
      backgroundColor: AppTheme.sheetBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < paragraphs.length; index++) ...[
            Text(paragraphs[index], style: bodyStyle),
            if (index < paragraphs.length - 1 || bullets.isNotEmpty) const SizedBox(height: AppSpacing.md),
          ],
          for (var index = 0; index < bullets.length; index++) ...[
            _Bullet(text: bullets[index]),
            if (index < bullets.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
