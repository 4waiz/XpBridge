import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../config/legal_urls.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // Pick up the one-shot message left behind by a completed account
    // deletion (either the password path or the post-reauth Google path)
    // and show it as a snackbar so the user knows the delete actually went
    // through before they land on the login form.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final message = await SupabaseService.consumeDeletionStatusMessage();
      if (message == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _signInByGoogle() async {
    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      await SupabaseService.signInWithGoogle();
      // Supabase OAuth usually handles redirection. 
      // The session refresh will happen after callback.
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      await SupabaseService.signIn(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      final appState = AppStateScope.of(context);
      await appState.refreshSession();
      if (!mounted) return;
      context.go(appState.defaultAuthenticatedLocation);
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final visibleError = _submitError ?? appState.errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 860;
            final sidePadding = compact ? AppSpacing.lg : AppSpacing.page;
            final heroSize = compact ? 60.0 : 76.0;
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
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: heroSize,
                        height: heroSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadiusLarge,
                          ),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadiusLarge,
                          ),
                          child: SvgPicture.asset(
                            'assets/image.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
                      Text('Welcome back', style: titleStyle),
                      SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
                      XPCard(
                        padding: EdgeInsets.all(
                          compact ? AppSpacing.lg : AppSpacing.xl,
                        ),
                        elevated: true,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log in',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(
                                height: compact ? AppSpacing.lg : AppSpacing.xl,
                              ),
                              TextFormField(
                                controller: _emailController,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                validator: _validatePassword,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
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
                              if (visibleError != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  visibleError,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.error),
                                ),
                              ],
                              SizedBox(
                                height: compact ? AppSpacing.lg : AppSpacing.xl,
                              ),
                              XPButton(
                                label: 'Log in',
                                icon: Icons.arrow_forward_rounded,
                                size: compact
                                    ? XPButtonSize.medium
                                    : XPButtonSize.large,
                                loading: _isLoading,
                                onPressed: _isLoading ? null : _submit,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              XPGoogleButton(
                                onPressed: _isLoading ? null : _signInByGoogle,
                                loading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: () => context.goNamed('signup'),
                          child: const Text('New here? Sign up'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
