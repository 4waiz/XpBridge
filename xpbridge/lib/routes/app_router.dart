import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../screens/admin/admin_preview_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/applications/student_applications_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/startup_dashboard_screen.dart';
import '../screens/dashboard/student_dashboard_screen.dart';
import '../screens/details/startup_detail_screen.dart';
import '../screens/details/student_detail_screen.dart';
import '../screens/interview/ai_interview_screen.dart';
import '../screens/onboarding/intro_screen.dart';
import '../screens/onboarding/startup_setup_screen.dart';
import '../screens/onboarding/student_setup_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_conditions_screen.dart';
import '../screens/legal/delete_account_screen.dart';
import '../screens/profile/startup_profile_screen.dart';
import '../screens/profile/student_profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../widgets/student_scaffold.dart';

class AppRouter {
  AppRouter({required this.appState});

  final AppState appState;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isGuestOnly =
          path == '/intro' || path == '/login' || path == '/signup';
      final isPublic =
          path == '/' ||
          isGuestOnly ||
          path == '/privacy-policy' ||
          path == '/terms' ||
          path == '/delete-account';

      // Bootstrap gate: until AppState has finished hydrating, pin everyone
      // to the splash route. Without this, public routes like `/login`
      // render for a frame before we know the real auth state — which is
      // exactly the flash the user was seeing after a Google callback.
      //
      // NOTE: we deliberately do NOT also block on `Uri.base` still having
      // `?code=...`. `main()` has already exchanged the code (or failed
      // to) and cleaned the URL by the time we get here. Blocking on the
      // query would pin the user to the splash forever if the URL ever
      // failed to clean — the exact infinite-loading bug we hit before.
      if (!appState.isInitialized) {
        debugPrint('[router] bootstrap in progress -> splash');
        return path == '/' ? null : '/';
      }

      debugPrint(
        '[router] route chosen: path=$path, isLoggedIn=${appState.isLoggedIn}, '
        'requiresAccountCompletion=${appState.requiresAccountCompletion}, '
        'needsProfileSetup=${appState.needsProfileSetup}',
      );

      if (appState.requiresAccountCompletion) {
        if (path == '/' || path == '/login') {
          return '/signup';
        }
        if (path != '/signup' &&
            path != '/privacy-policy' &&
            path != '/terms' &&
            path != '/delete-account') {
          return '/signup';
        }
        return null;
      }

      if (!appState.isLoggedIn) {
        if (path == '/') {
          return appState.onboardingComplete ? '/login' : '/intro';
        }
        if (!isPublic) {
          return appState.onboardingComplete ? '/login' : '/intro';
        }
        return null;
      }

      if (path == '/') {
        return appState.defaultAuthenticatedLocation;
      }

      if (appState.needsProfileSetup &&
          path != '/student/setup' &&
          path != '/startup/setup' &&
          path != '/admin' &&
          path != '/admin/preview' &&
          path != '/privacy-policy' &&
          path != '/delete-account') {
        return appState.defaultAuthenticatedLocation;
      }

      if (isGuestOnly) {
        return appState.defaultAuthenticatedLocation;
      }

      if (!appState.isAdmin && (path == '/admin' || path == '/admin/preview')) {
        return appState.defaultAuthenticatedLocation;
      }

      if (appState.isStudent &&
          path.startsWith('/startup') &&
          !path.startsWith('/startup/student/')) {
        return '/student/dashboard';
      }

      if (appState.isStartup &&
          path.startsWith('/student') &&
          !path.startsWith('/student/startup/')) {
        return '/startup/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        name: 'splash',
        path: '/',
        pageBuilder: (context, state) => _fade(const SplashScreen()),
      ),
      GoRoute(
        name: 'intro',
        path: '/intro',
        pageBuilder: (context, state) => _fade(const IntroScreen()),
      ),
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
      GoRoute(
        name: 'privacyPolicy',
        path: '/privacy-policy',
        pageBuilder: (context, state) => _fade(const PrivacyPolicyScreen()),
      ),
      GoRoute(
        name: 'terms',
        path: '/terms',
        pageBuilder: (context, state) =>
            _fade(const TermsConditionsScreen()),
      ),
      GoRoute(
        name: 'deleteAccount',
        path: '/delete-account',
        pageBuilder: (context, state) => _fade(DeleteAccountScreen()),
      ),
      GoRoute(
        name: 'studentSetup',
        path: '/student/setup',
        pageBuilder: (context, state) => _slide(const StudentSetupScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => StudentScaffold(child: child),
        routes: [
          GoRoute(
            name: 'studentDashboard',
            path: '/student/dashboard',
            pageBuilder: (context, state) =>
                _fade(const StudentDashboardScreen()),
          ),
          GoRoute(
            name: 'atChat',
            path: '/student/chat',
            pageBuilder: (context, state) => _slide(const AiChatScreen()),
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
            pageBuilder: (context, state) =>
                _slide(const StudentProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        name: 'startupDetail',
        path: '/student/startup/:id',
        pageBuilder: (context, state) => _slide(
          StartupDetailScreen(startupId: state.pathParameters['id'] ?? ''),
        ),
      ),
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
        pageBuilder: (context, state) => _slide(
          StudentDetailScreen(studentId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        name: 'startupProfile',
        path: '/startup/profile',
        pageBuilder: (context, state) => _slide(const StartupProfileScreen()),
      ),
      GoRoute(
        name: 'aiInterview',
        path: '/interview/:id',
        pageBuilder: (context, state) => _slide(
          AiInterviewScreen(interviewId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        name: 'admin',
        path: '/admin',
        pageBuilder: (context, state) => _slide(const AdminScreen()),
      ),
      GoRoute(
        name: 'adminPreview',
        path: '/admin/preview',
        pageBuilder: (context, state) => _slide(const AdminPreviewScreen()),
      ),
    ],
  );

  static CustomTransitionPage<void> _fade(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  static CustomTransitionPage<void> _slide(Widget child) {
    return CustomTransitionPage<void>(
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
