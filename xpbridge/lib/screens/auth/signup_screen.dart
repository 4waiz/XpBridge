import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../config/legal_urls.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/social_links_row.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  UserRole? _selectedRole;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Use at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@]+@gmail\.com$');
    if (!regex.hasMatch(email)) {
      return 'Please use a real @gmail.com address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Use at least 8 characters';
    return null;
  }

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return; // prevent double taps
    if (_selectedRole == null) {
      setState(() => _submitError = 'Select a role to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      final role = _selectedRole == UserRole.student ? 'student' : 'startup';
      await SupabaseService.signInWithGoogle(role: role);
      // On web, the future returns before the redirect completes, so
      // post-auth work happens in the OAuth callback path. On Android the
      // session is already live — drive straight into the authenticated
      // flow so the user doesn't stare at a spinning sign-up screen.
      if (!mounted) return;
      final appState = AppStateScope.of(context);
      await appState.refreshSession();
      if (!mounted) return;
      context.go(appState.defaultAuthenticatedLocation);
    } on XpServiceException catch (error) {
      if (!mounted) return;
      if (identical(error, SupabaseService.googleSignInCancelled)) {
        setState(() => _submitError = null);
      } else {
        setState(() => _submitError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final hasOAuthUser = SupabaseService.currentUser != null;
    final isFormValid = hasOAuthUser ? true : _formKey.currentState!.validate();
    if (!isFormValid || _selectedRole == null) {
      setState(() {
        _submitError = _selectedRole == null ? 'Select a role to continue.' : null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      final role = _selectedRole == UserRole.student ? 'student' : 'startup';
      if (hasOAuthUser) {
        await SupabaseService.completeOAuthProfile(
          role: role,
          name: _nameController.text.trim(),
        );
      } else {
        await SupabaseService.signUp(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: role,
        );
      }

      if (!mounted) return;
      final appState = AppStateScope.of(context);
      await appState.refreshSession();
      if (!mounted) return;
      context.go(appState.defaultAuthenticatedLocation);
    } on XpServiceException catch (error) {
      // If the message indicates email confirmation, show it as info not error
      if (error.message.contains('Check your inbox')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            duration: const Duration(seconds: 5),
          ),
        );
        context.goNamed('login');
        return;
      }
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOAuthUser = SupabaseService.currentUser != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 860;
            final sidePadding = compact ? AppSpacing.lg : AppSpacing.page;
            final titleStyle = compact
                ? Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )
                : Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  );
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  sidePadding,
                  sidePadding,
                  sidePadding,
                  sidePadding + bottomInset,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XPHeaderButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.goNamed('login'),
                      ),
                      SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                      Text(
                        hasOAuthUser ? 'Finish your account' : 'Create your account',
                        style: titleStyle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hasOAuthUser
                            ? 'Pick a role and continue.'
                            : 'Choose your lane and get moving.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              title: 'Student',
                              subtitle: 'Build profile and apply',
                              icon: Icons.school_rounded,
                              compact: compact,
                              selected: _selectedRole == UserRole.student,
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.student;
                                  _submitError = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _RoleCard(
                              title: 'Startup',
                              subtitle: 'Launch missions and hire',
                              icon: Icons.rocket_launch_rounded,
                              compact: compact,
                              selected: _selectedRole == UserRole.startup,
                              onTap: () {
                                setState(() {
                                  _selectedRole = UserRole.startup;
                                  _submitError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                      XPCard(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        elevated: true,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!hasOAuthUser) ...[
                                TextFormField(
                                  controller: _nameController,
                                  validator: _validateName,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _emailController,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.mail_outline_rounded),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextFormField(
                                  controller: _passwordController,
                                  validator: _validatePassword,
                                  obscureText: _obscurePassword,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    helperText: compact ? null : 'Use at least 8 characters.',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        );
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (_submitError != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _submitError!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.error),
                                ),
                              ],
                              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                              XPButton(
                                label: hasOAuthUser ? 'Continue' : 'Create account',
                                icon: Icons.arrow_forward_rounded,
                                size: compact
                                    ? XPButtonSize.medium
                                    : XPButtonSize.large,
                                loading: _isLoading,
                                onPressed: _isLoading ? null : _submit,
                              ),
                              if (!hasOAuthUser) ...[
                                const SizedBox(height: AppSpacing.sm),
                                XPGoogleButton(
                                  label: 'Sign up with Google',
                                  onPressed: _isLoading ? null : _signUpWithGoogle,
                                  loading: _isLoading,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: () => context.goNamed('login'),
                          child: const Text('Already have an account? Log in'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          'By creating an account you agree to our',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(LegalUrls.privacyPolicy),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(
                                'Privacy Policy',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryDark,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            Text(
                              'and',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(LegalUrls.termsConditions),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(
                                'Terms & Conditions',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryDark,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Center(child: SocialLinksRow()),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.3)
                : AppTheme.border,
          ),
          boxShadow: selected ? AppTheme.softShadow : AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 40 : 46,
              height: compact ? 40 : 46,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
              ),
              child: Icon(icon, color: AppTheme.text, size: compact ? 20 : 24),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
