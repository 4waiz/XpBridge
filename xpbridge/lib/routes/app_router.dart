import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/applications/student_applications_screen.dart';
import '../screens/dashboard/startup_dashboard_screen.dart';
import '../screens/dashboard/student_dashboard_screen.dart';
import '../screens/details/startup_detail_screen.dart';
import '../screens/details/student_detail_screen.dart';
import '../screens/onboarding/startup_setup_screen.dart';
import '../screens/onboarding/student_setup_screen.dart';
import '../screens/profile/startup_profile_screen.dart';
import '../screens/profile/student_profile_screen.dart';
import '../screens/onboarding/intro_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/chat/startup_ai_chat_screen.dart';

class AppRouter {
  AppRouter({required this.appState});

  final AppState appState;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    routes: [
      // Splash
      GoRoute(
        name: 'splash',
        path: '/',
        pageBuilder: (context, state) => _fade(const SplashScreen()),
      ),

      // Intro/Onboarding
      GoRoute(
        name: 'intro',
        path: '/intro',
        pageBuilder: (context, state) => _fade(const IntroScreen()),
      ),

      // Auth
      GoRoute(
        name: 'login',
        path: '/login',
        pageBuilder: (context, state) => _slide(const LoginScreen()),
      ),
      GoRoute(
        name: 'signup',
        path: '/signup',
        pageBuilder: (context, state) => _slide(const SignupScreen()),
      ),

      // Role Select (keeping for backward compatibility, redirects to login)
      GoRoute(
        name: 'roleSelect',
        path: '/role',
        redirect: (context, state) => '/login',
      ),

      // Student Flow
      GoRoute(
        name: 'studentSetup',
        path: '/student/setup',
        pageBuilder: (context, state) => _slide(const StudentSetupScreen()),
      ),
      GoRoute(
        name: 'studentDashboard',
        path: '/student/dashboard',
        pageBuilder: (context, state) => _fade(const StudentDashboardScreen()),
      ),
      GoRoute(
        name: 'startupDetail',
        path: '/student/startup/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slide(StartupDetailScreen(startupId: id));
        },
      ),
      GoRoute(
        name: 'myApplications',
        path: '/student/applications',
        pageBuilder: (context, state) =>
            _slide(const StudentApplicationsScreen()),
      ),
      GoRoute(
        name: 'studentProfile',
        path: '/student/profile',
        pageBuilder: (context, state) => _slide(const StudentProfileScreen()),
      ),
      GoRoute(
        name: 'aiChat',
        path: '/student/ai-chat',
        pageBuilder: (context, state) => _slide(const AiChatScreen()),
      ),

      // Startup Flow
      GoRoute(
        name: 'startupSetup',
        path: '/startup/setup',
        pageBuilder: (context, state) => _slide(const StartupSetupScreen()),
      ),
      GoRoute(
        name: 'startupDashboard',
        path: '/startup/dashboard',
        pageBuilder: (context, state) => _fade(const StartupDashboardScreen()),
      ),
      GoRoute(
        name: 'studentDetail',
        path: '/startup/student/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slide(StudentDetailScreen(studentId: id));
        },
      ),
      GoRoute(
        name: 'startupProfile',
        path: '/startup/profile',
        pageBuilder: (context, state) => _slide(const StartupProfileScreen()),
      ),
      GoRoute(
        name: 'startupAiChat',
        path: '/startup/ai-chat',
        pageBuilder: (context, state) => _slide(const StartupAiChatScreen()),
      ),
    ],
  );

  static CustomTransitionPage _fade(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage _slide(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
    );
  }
}
