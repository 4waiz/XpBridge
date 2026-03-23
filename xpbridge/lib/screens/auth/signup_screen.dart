import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../services/user_file_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole? _selectedRole;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _roleError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String? _validateName(String name) {
    if (name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!email.contains('@')) {
      return 'Email must contain @';
    }
    if (!_isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    setState(() {
      _nameError = _validateName(_nameController.text.trim());
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(_passwordController.text);
      _roleError = _selectedRole == null ? 'Please select a role' : null;
    });

    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _roleError == null) {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final role = _selectedRole == UserRole.student ? 'student' : 'startup';

      if (await UserFileService.userExists(email)) {
        setState(() {
          _emailError = 'Account already exists. Please login.';
        });
        return;
      }

      final saved = await UserFileService.saveUser(email, password);
      if (!saved) {
        setState(() {
          _emailError = 'Failed to create account. Please try again.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', name);
      await prefs.setString('user_role', role);

      if (!mounted) return;

      final appState = AppStateScope.of(context);
      appState.login(role: _selectedRole!);

      if (_selectedRole == UserRole.student) {
        context.goNamed('studentSetup');
      } else {
        context.goNamed('startupSetup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
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
                'Choose your role, set up your profile, and redesign your path into real experience.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'I am joining as',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      title: 'Student',
                      subtitle: 'Learn through startup missions',
                      icon: Icons.school_rounded,
                      selected: _selectedRole == UserRole.student,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.student;
                          _roleError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _RoleCard(
                      title: 'Startup',
                      subtitle: 'Find motivated early talent',
                      icon: Icons.rocket_launch_rounded,
                      selected: _selectedRole == UserRole.startup,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.startup;
                          _roleError = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_roleError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _roleError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              XPCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                elevated: true,
                radius: AppTheme.cornerRadiusLarge,
                child: Column(
                  children: [
                    XPTextField(
                      controller: _nameController,
                      labelText: 'Full name',
                      hintText: 'Enter your full name',
                      errorText: _nameError,
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      errorText: _emailError,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'At least 6 characters',
                      errorText: _passwordError,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      obscureText: _obscurePassword,
                      onSuffixTap: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      onChanged: (_) => setState(() => _passwordError = null),
                      onSubmitted: (_) => _handleSignup(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPButton(
                      label: 'Create account',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleSignup,
                    ),
                  ],
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
            color: selected ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
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
              child: Icon(
                icon,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
