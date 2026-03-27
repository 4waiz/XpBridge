import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app.dart';
import '../../theme/app_theme.dart';

class StudentScaffold extends StatelessWidget {
  const StudentScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final location = state.matchedLocation;
    final appState = AppStateScope.of(context);
    final aiEnabled = appState.aiFeaturesEnabled;

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
        child: BottomNavigationBar(
          currentIndex: _calculateIndex(location, aiEnabled),
          onTap: (index) => _onTap(context, index, aiEnabled),
          backgroundColor: AppTheme.cardBackground,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Missions',
            ),
            if (aiEnabled)
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: Icon(Icons.chat_bubble_rounded),
                label: 'AI Chat',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'Apps',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int _calculateIndex(String location, bool aiEnabled) {
    if (location.startsWith('/student/dashboard')) return 0;
    if (aiEnabled && location.startsWith('/student/chat')) return 1;
    if (location.startsWith('/student/applications')) return aiEnabled ? 2 : 1;
    if (location.startsWith('/student/profile')) return aiEnabled ? 3 : 2;
    return 0;
  }

  void _onTap(BuildContext context, int index, bool aiEnabled) {
    switch (index) {
      case 0:
        context.goNamed('studentDashboard');
        break;
      case 1:
        context.goNamed(aiEnabled ? 'atChat' : 'myApplications');
        break;
      case 2:
        context.goNamed(aiEnabled ? 'myApplications' : 'studentProfile');
        break;
      case 3:
        context.goNamed('studentProfile');
        break;
    }
  }
}
