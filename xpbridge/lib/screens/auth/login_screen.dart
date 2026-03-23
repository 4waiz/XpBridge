import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/student_profile.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../services/user_file_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';

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

      // Check if user exists in the txt file
      final userExists = await UserFileService.userExists(enteredEmail);
      if (!userExists) {
        setState(() {
          _emailError = 'Account not found. Please sign up first.';
        });
        return;
      }

      // Validate credentials from txt file
      final isValid = await UserFileService.validateUser(enteredEmail, enteredPassword);
      if (!isValid) {
        setState(() {
          _passwordError = 'Incorrect password. Please try again.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('user_role');

      if (!mounted) return;

      // Save login state for auto-login on next app launch
      await prefs.setBool('is_logged_in', true);

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
        context.goNamed('startupDashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Logo and welcome section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your journey',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login form card
                    XPCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: _emailError != null
                                    ? AppTheme.error
                                    : AppTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: _emailError != null
                                  ? AppTheme.error.withValues(alpha: 0.05)
                                  : AppTheme.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: _emailError != null
                                    ? BorderSide(color: AppTheme.error)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: _emailError != null
                                    ? BorderSide(color: AppTheme.error)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _emailError != null
                                      ? AppTheme.error
                                      : AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorText: _emailError,
                              errorStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.text,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: _passwordError != null
                                    ? AppTheme.error
                                    : AppTheme.textMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: _passwordError != null
                                  ? AppTheme.error.withValues(alpha: 0.05)
                                  : AppTheme.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: _passwordError != null
                                    ? BorderSide(color: AppTheme.error)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: _passwordError != null
                                    ? BorderSide(color: AppTheme.error)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: _passwordError != null
                                      ? AppTheme.error
                                      : AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorText: _passwordError,
                              errorStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          XPButton(
                            label: 'Sign In',
                            icon: Icons.login_rounded,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sign up link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.goNamed('signup'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<UserRole>(
                onSelected: (role) async {
                  final appState = AppStateScope.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  
                  await prefs.setBool('is_logged_in', true);
                  await prefs.setString('user_role', role == UserRole.student ? 'student' : 'startup');
                  
                  if (role == UserRole.student) {
                    if (prefs.getString('profile_name') == null) {
                      await prefs.setString('profile_name', 'Demo Student');
                      await prefs.setString('user_email', 'student@demo.com');
                      await prefs.setStringList('profile_skills', ['Flutter', 'Dart', 'Design']);
                    }
                  } else {
                    if (prefs.getString('startup_name') == null) {
                      await prefs.setString('startup_name', 'Demo Startup');
                      await prefs.setString('user_email', 'startup@demo.com');
                    }
                  }

                  await appState.loadUserSession();
                  
                  if (mounted) {
                    if (role == UserRole.student) {
                      context.goNamed('studentDashboard');
                    } else {
                      context.goNamed('startupDashboard');
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: UserRole.student,
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text('Skip as Student'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: UserRole.startup,
                    child: Row(
                      children: [
                        Icon(Icons.business_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text('Skip as Startup'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
