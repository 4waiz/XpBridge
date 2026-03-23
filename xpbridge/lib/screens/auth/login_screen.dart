import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../models/student_profile.dart';
import '../../services/user_file_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
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

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text.trim());
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError == null && _passwordError == null) {
      final enteredEmail = _emailController.text.trim().toLowerCase();
      final enteredPassword = _passwordController.text;

      final userExists = await UserFileService.userExists(enteredEmail);
      if (!userExists) {
        setState(() {
          _emailError = 'Account not found. Please sign up first.';
        });
        return;
      }

      final isValid = await UserFileService.validateUser(
        enteredEmail,
        enteredPassword,
      );
      if (!isValid) {
        setState(() {
          _passwordError = 'Incorrect password. Please try again.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('user_role');
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      final appState = AppStateScope.of(context);
      final role = savedRole == 'student' ? UserRole.student : UserRole.startup;
      appState.login(role: role);

      if (role == UserRole.student) {
        final name = prefs.getString('profile_name');
        if (name != null && name.isNotEmpty) {
          final profile = StudentProfile(
            id: 'user_restored',
            name: name,
            email: enteredEmail,
            bio: prefs.getString('profile_bio'),
            education: prefs.getString('profile_education'),
            skills: prefs.getStringList('profile_skills') ?? [],
            availabilityHours: prefs.getDouble('profile_hours') ?? 10,
            createdAt: DateTime.now(),
            xpPoints: 0,
            level: 1,
            missionsCompletedCount: 0,
          );
          appState.saveStudentProfile(profile);
        }
        if (!mounted) return;
        context.goNamed('studentDashboard');
      } else {
        final companyName = prefs.getString('startup_name');
        if (companyName != null && companyName.isNotEmpty) {
          final storedRoles = prefs.getString('startup_roles');
          final roles = storedRoles != null && storedRoles.isNotEmpty
              ? (jsonDecode(storedRoles) as List<dynamic>)
                    .map(
                      (item) => StartupRole.fromMap(
                        Map<String, dynamic>.from(item as Map),
                      ),
                    )
                    .where((role) => role.title.isNotEmpty)
                    .toList()
              : <StartupRole>[];
          final profile = StartupProfile(
            id: 'startup_restored',
            companyName: companyName,
            email: enteredEmail,
            description: prefs.getString('startup_description') ?? '',
            industry: prefs.getString('startup_industry') ?? '',
            requiredSkills: prefs.getStringList('startup_skills') ?? [],
            openRoles: roles,
            projectDetails: prefs.getString('startup_project'),
            logoBase64: prefs.getString('startup_logo_base64'),
            createdAt: DateTime.now(),
          );
          appState.saveStartupProfile(profile);
        }
        if (!mounted) return;
        context.goNamed('startupDashboard');
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
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(
                    AppTheme.cornerRadiusLarge,
                  ),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 34,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Welcome back',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to keep building experience, tracking applications, and discovering new missions.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              XPCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                elevated: true,
                radius: AppTheme.cornerRadiusLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log in',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Use the email and password you created on XPBridge.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      errorText: _emailError,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {
                        _emailError = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      errorText: _passwordError,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSuffixTap: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      onChanged: (_) => setState(() {
                        _passwordError = null;
                      }),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                radius: AppTheme.cornerRadiusLarge,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New here? Create an account to set up your student or startup profile.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    XPOutlinedButton(
                      label: 'Sign up',
                      expand: false,
                      size: XPButtonSize.medium,
                      onPressed: () => context.goNamed('signup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
