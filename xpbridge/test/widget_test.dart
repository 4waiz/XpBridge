import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xpbridge/app.dart';
import 'package:xpbridge/models/ai_interview.dart';
import 'package:xpbridge/models/application.dart';
import 'package:xpbridge/models/mission.dart';
import 'package:xpbridge/models/student_profile.dart';
import 'package:xpbridge/models/startup_profile.dart';
import 'package:xpbridge/screens/applications/student_applications_screen.dart';
import 'package:xpbridge/screens/auth/login_screen.dart';
import 'package:xpbridge/screens/dashboard/student_dashboard_screen.dart';
import 'package:xpbridge/screens/onboarding/student_setup_screen.dart';

void main() {
  Widget wrapWithState(Widget child, AppState state) {
    return AppStateScope(
      notifier: state,
      child: MaterialApp(home: child),
    );
  }

  final student = StudentProfile(
    id: 'student-1',
    name: 'Alex Chen',
    email: 'alex@example.com',
    bio: 'Flutter builder shipping mobile UI.',
    education: 'BSc Computer Science',
    skills: const ['Flutter', 'Firebase', 'UI/UX Design'],
    availabilityHours: 12,
    portfolioUrl: 'https://alex.dev',
    githubUrl: 'https://github.com/alex',
    resumeUrl: 'https://files.example.com/resume.pdf',
    resumeFileName: 'resume.pdf',
    resumeMimeType: 'application/pdf',
    createdAt: DateTime(2026, 1, 1),
    xpPoints: 320,
    level: 2,
    missionsCompletedCount: 1,
  );

  final startup = StartupProfile(
    id: 'startup-1',
    companyName: 'BrightSeed Labs',
    email: 'hello@brightseed.io',
    description: 'Edtech startup building modern learning tools.',
    industry: 'Education',
    requiredSkills: const ['Flutter', 'Firebase'],
    websiteUrl: 'https://brightseed.io',
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('login screen validates required fields', (tester) async {
    await tester.pumpWidget(wrapWithState(const LoginScreen(), AppState()));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('student dashboard renders live mission cards', (tester) async {
    final state = AppState()
      ..debugSeed(
        role: UserRole.student,
        studentProfile: student,
        students: [student],
        startups: [startup],
        missions: [
          Mission(
            id: 'mission-1',
            startupId: startup.id,
            startupName: startup.companyName,
            title: 'Flutter Builder',
            description: 'Help ship product polish and onboarding updates.',
            learningOutcome: 'Build production Flutter UI.',
            requiredSkills: const ['Flutter', 'Firebase'],
            status: 'open',
            createdAt: DateTime(2026, 1, 2),
            websiteUrl: startup.websiteUrl,
            industry: startup.industry,
          ),
        ],
      );

    await tester.pumpWidget(
      wrapWithState(const StudentDashboardScreen(), state),
    );
    await tester.pumpAndSettle();

    expect(find.text('Discover missions'), findsOneWidget);
    expect(find.text('Flutter Builder'), findsOneWidget);
    expect(find.text('BrightSeed Labs'), findsOneWidget);
  });

  testWidgets('applications screen renders stateful application cards', (
    tester,
  ) async {
    final application = Application(
      id: 'app-1',
      missionId: 'mission-1',
      studentId: student.id,
      startupId: startup.id,
      studentName: student.name,
      startupName: startup.companyName,
      roleTitle: 'Flutter Builder',
      status: ApplicationStatus.interviewing,
      appliedAt: DateTime(2026, 2, 1),
    );
    final interview = AiInterview(
      id: 'interview-1',
      applicationId: application.id,
      missionId: 'mission-1',
      studentId: student.id,
      startupId: startup.id,
      questions: const ['Tell us about a project.'],
      status: AiInterviewStatus.pending,
    );

    final state = AppState()
      ..debugSeed(
        role: UserRole.student,
        studentProfile: student,
        students: [student],
        startups: [startup],
        applications: [application],
        aiInterviews: [interview],
      );

    await tester.pumpWidget(
      wrapWithState(const StudentApplicationsScreen(), state),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Builder'), findsOneWidget);
    expect(find.text('Interviewing'), findsOneWidget);
    expect(find.text('AI interview requested'), findsOneWidget);
  });

  testWidgets('student setup enforces required fields before save', (
    tester,
  ) async {
    final state = AppState()
      ..debugSeed(role: UserRole.student, studentProfile: null);

    await tester.pumpWidget(wrapWithState(const StudentSetupScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Education is required'), findsOneWidget);
    expect(find.text('Bio is required'), findsOneWidget);
  });
}
