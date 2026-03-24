import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../models/student_profile.dart';
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
  bool _isLoading = false;

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
      setState(() => _isLoading = true);
      
      try {
        final enteredEmail = _emailController.text.trim().toLowerCase();
        final enteredPassword = _passwordController.text;

        final response = await SupabaseService.signIn(
          email: enteredEmail,
          password: enteredPassword,
        );

        final user = response.user;
        if (user == null) throw Exception('Login failed');

        // Fetch user role and profile from 'profiles' table
        final profileData = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        final roleStr = profileData['role'] as String;
        final role = roleStr == 'student' ? UserRole.student : UserRole.startup;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_role', roleStr);

        if (!mounted) return;

        final appState = AppStateScope.of(context);
        appState.login(role: role);

        if (role == UserRole.student) {
          final profile = StudentProfile.fromMap(profileData);
          appState.saveStudentProfile(profile);
          context.goNamed('studentDashboard');
        } else {
          final profile = StartupProfile.fromMap(profileData);
          appState.saveStartupProfile(profile);
          context.goNamed('startupDashboard');
        }
      } on AuthException catch (e) {
        setState(() {
          if (e.message.toLowerCase().contains('invalid login credentials')) {
            _passwordError = 'Invalid email or password.';
          } else {
            _emailError = e.message;
          }
        });
      } catch (e) {
        setState(() {
          _emailError = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
                  borderRadius: BorderRadius.circular(
                    AppTheme.cornerRadiusLarge,
                  ),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppTheme.cornerRadiusLarge,
                  ),
                  child: Image.asset(
                    'assets/image.png',
                    fit: BoxFit.cover,
                  ),
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
                      loading: _isLoading,
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
