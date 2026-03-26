import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
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
    if (_selectedRole == null) {
      setState(() => _submitError = 'Select a role to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      await SupabaseService.signInWithGoogle();
      // Role handling will be needed in the post-login callback 
      // or through standard profile syncing.
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
    if (!_formKey.currentState!.validate() || _selectedRole == null) {
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
      await SupabaseService.signUp(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: role,
      );

      if (!mounted) return;
      final appState = AppStateScope.of(context);
      appState.login(role: _selectedRole!);
      context.goNamed(
        _selectedRole == UserRole.student ? 'studentSetup' : 'startupSetup',
      );
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  XPHeaderButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.goNamed('login'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose the workspace you need first. Students must upload a CV in setup, and startups move straight into company profile creation.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Student',
                          subtitle: 'Profile, CV, portfolio, and mission applications',
                          icon: Icons.school_rounded,
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
                          subtitle: 'Company setup, missions, applicants, and feedback',
                          icon: Icons.rocket_launch_rounded,
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
                  const SizedBox(height: AppSpacing.xl),
                  XPCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    elevated: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            validator: _validateName,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full name or company owner name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            validator: _validatePassword,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: 'Use at least 8 characters.',
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
                          if (_submitError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _submitError!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.error),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          XPButton(
                            label: 'Create account',
                            icon: Icons.arrow_forward_rounded,
                            loading: _isLoading,
                            onPressed: _isLoading ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPGoogleButton(
                            label: 'Sign up with Google',
                            onPressed: _isLoading ? null : _signUpWithGoogle,
                            loading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => context.goNamed('login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
              ),
              child: Icon(icon, color: AppTheme.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
