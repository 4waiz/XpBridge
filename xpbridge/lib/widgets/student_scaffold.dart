import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class StudentScaffold extends StatelessWidget {
  const StudentScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final location = state.matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
          currentIndex: _calculateIndex(location),
          onTap: (index) => _onTap(context, index),
          backgroundColor: AppTheme.cardBackground,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Missions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'CV Builder',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
        ),
      ),
    );
  }

  int _calculateIndex(String location) {
    if (location.startsWith('/student/dashboard')) return 0;
    if (location.startsWith('/student/cv-builder')) return 1;
    if (location.startsWith('/student/chat')) return 2;
    // Applications is reached from inside Profile, so keep the Profile tab
    // highlighted while viewing it.
    if (location.startsWith('/student/profile') ||
        location.startsWith('/student/applications')) {
      return 3;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed('studentDashboard');
        break;
      case 1:
        context.goNamed('cvBuilder');
        break;
      case 2:
        context.goNamed('atChat');
        break;
      case 3:
        context.goNamed('studentProfile');
        break;
    }
  }
}
