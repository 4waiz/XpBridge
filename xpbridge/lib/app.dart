import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpbridge/routes/app_router.dart';
import 'package:xpbridge/theme/app_theme.dart';

import 'data/dummy_data.dart';
import 'models/application.dart';
import 'models/event_log_entry.dart';
import 'models/student_profile.dart';
import 'models/startup_profile.dart';
import 'models/startup_role.dart';

enum UserRole { student, startup }

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserRole? _userRole;
  StudentProfile? _studentProfile;
  StartupProfile? _startupProfile;
  List<Application> _applications = List<Application>.from(
    DummyData.applications,
  );
  List<EventLogEntry> _eventLog = [];
  bool _xpFeedOptOut = false;

  bool get isLoggedIn => _isLoggedIn;
  UserRole? get userRole => _userRole;
  StudentProfile? get studentProfile => _studentProfile;
  StartupProfile? get startupProfile => _startupProfile;
  List<Application> get applications => _applications;
  List<EventLogEntry> get eventLog => _eventLog;
  bool get xpFeedOptOut => _xpFeedOptOut;

  bool get isStudent => _userRole == UserRole.student;
  bool get isStartup => _userRole == UserRole.startup;

  void login({required UserRole role}) {
    _isLoggedIn = true;
    _userRole = role;
    if (_applications.isEmpty) {
      _applications = List<Application>.from(DummyData.applications);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userRole = null;
    _studentProfile = null;
    _startupProfile = null;
    _applications = [];
    _eventLog = [];
    _xpFeedOptOut = false;

    // Clear login state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);

    notifyListeners();
  }

  /// Loads user session from SharedPreferences on app startup
  /// Returns true if user was logged in, false otherwise
  Future<bool> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) return false;

    final roleStr = prefs.getString('user_role');
    if (roleStr == null) return false;

    final role = roleStr == 'student' ? UserRole.student : UserRole.startup;

    if (role == UserRole.student) {
      // Reconstruct StudentProfile from saved keys
      final name = prefs.getString('profile_name') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final bio = prefs.getString('profile_bio');
      final education = prefs.getString('profile_education');
      final skills = prefs.getStringList('profile_skills') ?? [];
      final hours = prefs.getDouble('profile_hours') ?? 10.0;

      if (name.isEmpty) return false;

      _studentProfile = StudentProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        bio: bio,
        education: education,
        skills: skills,
        availabilityHours: hours,
        createdAt: DateTime.now(),
      );
    } else {
      // Reconstruct StartupProfile from saved keys
      final companyName = prefs.getString('startup_name') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final description = prefs.getString('startup_description');
      final industry = prefs.getString('startup_industry');
      final skills = prefs.getStringList('startup_skills') ?? [];
      final project = prefs.getString('startup_project');
      final rolesJson = prefs.getString('startup_roles');
      final logoBase64 = prefs.getString('startup_logo_base64');

      if (companyName.isEmpty) return false;

      List<StartupRole> roles = [];
      if (rolesJson != null && rolesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(rolesJson) as List<dynamic>;
          roles = decoded
              .map(
                (item) =>
                    StartupRole.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
        } catch (_) {
          roles = [];
        }
      }

      _startupProfile = StartupProfile(
        id: 'startup_${DateTime.now().millisecondsSinceEpoch}',
        companyName: companyName,
        email: email,
        description: description ?? '',
        industry: industry ?? '',
        requiredSkills: skills,
        projectDetails: project,
        openRoles: roles,
        logoBase64: logoBase64,
        createdAt: DateTime.now(),
      );
    }

    _isLoggedIn = true;
    _userRole = role;

    // Also load applications
    await loadApplications();

    notifyListeners();
    return true;
  }

  void setUserRole(UserRole role) {
    _userRole = role;
    notifyListeners();
  }

  void saveStudentProfile(StudentProfile profile) {
    _studentProfile = profile;
    _recalculateStudentProgress();
    notifyListeners();
  }

  void saveStartupProfile(StartupProfile profile) {
    _startupProfile = profile;
    notifyListeners();
  }

  Future<void> setFeedOptOut(bool value) async {
    _xpFeedOptOut = value;
    notifyListeners();
    await _persistFeedPreference();
  }

  Future<void> loadApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('applications');
    final storedEvents = prefs.getString('xp_event_log');
    _xpFeedOptOut = prefs.getBool('xp_feed_opt_out') ?? false;
    if (storedEvents != null && storedEvents.isNotEmpty) {
      try {
        final decodedEvents = jsonDecode(storedEvents) as List<dynamic>;
        _eventLog = decodedEvents
            .map(
              (item) =>
                  EventLogEntry.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        _eventLog = [];
      }
    }
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored) as List<dynamic>;
        _applications = decoded
            .map(
              (item) =>
                  Application.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        _applications = List<Application>.from(DummyData.applications);
      }
    }
    _recalculateStudentProgress();
    notifyListeners();
  }

  Future<void> _persistApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'applications',
      jsonEncode(_applications.map((app) => app.toMap()).toList()),
    );
  }

  Future<void> _persistEventLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'xp_event_log',
      jsonEncode(_eventLog.map((event) => event.toMap()).toList()),
    );
  }

  Future<void> _persistFeedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('xp_feed_opt_out', _xpFeedOptOut);
  }

  String _firstName(String name) => name.split(' ').first;

  void _logEvent(String type, String displayText, String firstName) {
    if (_xpFeedOptOut) return;
    final entry = EventLogEntry(
      type: type,
      timestamp: DateTime.now(),
      displayText: displayText,
      firstName: firstName,
    );
    _eventLog = [entry, ..._eventLog].take(12).toList();
    unawaited(_persistEventLog());
    notifyListeners();
  }

  int _levelForXp(int xp) {
    if (xp >= 900) return 4;
    if (xp >= 500) return 3;
    if (xp >= 200) return 2;
    return 1;
  }

  void _recalculateStudentProgress() {
    final profile = _studentProfile;
    if (profile == null) return;
    final previousLevel = profile.level;

    final studentApps = getApplicationsForStudent(profile.id);
    final completed = studentApps
        .where(
          (app) =>
              app.status == ApplicationStatus.completed ||
              app.completedAt != null,
        )
        .toList();

    final completedCount = completed.length;
    var xp = completedCount * 100;
    if (completedCount > 0) {
      xp += 50; // first completion bonus
    }
    xp +=
        completed
            .where(
              (app) =>
                  app.reflectionDid?.isNotEmpty == true ||
                  app.reflectionLearned?.isNotEmpty == true,
            )
            .length *
        15;
    xp +=
        completed
            .where(
              (app) =>
                  app.mentorRating != null ||
                  app.mentorFeedbackText?.isNotEmpty == true,
            )
            .length *
        25;

    final newLevel = _levelForXp(xp);
    _studentProfile = profile.copyWith(
      xpPoints: xp,
      missionsCompletedCount: completedCount,
      level: newLevel,
    );
    if (newLevel > previousLevel) {
      _logEvent(
        'level_up',
        'Leveled up to L$newLevel',
        _firstName(profile.name),
      );
    }
  }

  Future<void> addApplication(Application application) async {
    _applications = [..._applications, application];
    _recalculateStudentProgress();
    notifyListeners();
    await _persistApplications();
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    Application? updatedApplication;
    _applications = _applications.map((app) {
      if (app.id == applicationId) {
        final updated = app.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          completedAt: status == ApplicationStatus.completed
              ? (app.completedAt ?? DateTime.now())
              : app.completedAt,
        );
        updatedApplication = updated;
        return updated;
      }
      return app;
    }).toList();
    _recalculateStudentProgress();
    notifyListeners();
    await _persistApplications();
    if (status == ApplicationStatus.completed && updatedApplication != null) {
      _logEvent(
        'completion',
        'Completed ${updatedApplication!.roleTitle ?? 'mission'}',
        _firstName(updatedApplication!.studentName),
      );
    }
  }

  Future<void> saveReflection(
    String applicationId, {
    String? did,
    String? learned,
    List<String>? skillsPracticed,
    int? hoursSpent,
    String? deliverableUrl,
    String? deliverableType,
  }) async {
    Application? updatedApp;
    _applications = _applications.map((app) {
      if (app.id == applicationId) {
        final updated = app.copyWith(
          reflectionDid: did ?? app.reflectionDid,
          reflectionLearned: learned ?? app.reflectionLearned,
          skillsPracticed: skillsPracticed ?? app.skillsPracticed,
          hoursSpent: hoursSpent ?? app.hoursSpent,
          deliverableUrl: deliverableUrl ?? app.deliverableUrl,
          deliverableType: deliverableType ?? app.deliverableType,
          updatedAt: DateTime.now(),
          completedAt: app.completedAt ?? DateTime.now(),
        );
        updatedApp = updated;
        return updated;
      }
      return app;
    }).toList();
    _recalculateStudentProgress();
    notifyListeners();
    await _persistApplications();
    if (updatedApp != null) {
      _logEvent(
        'reflection',
        'Shared a reflection for ${updatedApp!.roleTitle ?? 'a mission'}',
        _firstName(updatedApp!.studentName),
      );
    }
  }

  Future<void> saveMentorFeedback(
    String applicationId, {
    int? rating,
    String? feedback,
    List<String>? strengths,
    List<String>? growthAreas,
    List<String>? endorsedSkills,
  }) async {
    Application? updatedApp;
    _applications = _applications.map((app) {
      if (app.id == applicationId) {
        final updated = app.copyWith(
          mentorRating: rating ?? app.mentorRating,
          mentorFeedbackText: feedback ?? app.mentorFeedbackText,
          strengths: strengths ?? app.strengths,
          growthAreas: growthAreas ?? app.growthAreas,
          endorsedSkills: endorsedSkills ?? app.endorsedSkills,
          feedbackAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        updatedApp = updated;
        return updated;
      }
      return app;
    }).toList();
    _recalculateStudentProgress();
    notifyListeners();
    await _persistApplications();
    if (updatedApp != null) {
      _logEvent(
        'feedback',
        'Received mentor feedback for ${updatedApp!.roleTitle ?? 'a mission'}',
        _firstName(updatedApp!.studentName),
      );
    }
  }

  List<Application> getApplicationsForStudent(String studentId) {
    return _applications.where((app) => app.studentId == studentId).toList();
  }

  List<Application> getApplicationsForStartup(String startupId) {
    return _applications.where((app) => app.startupId == startupId).toList();
  }

  Application? getApplicationById(String applicationId) {
    try {
      return _applications.firstWhere((app) => app.id == applicationId);
    } catch (_) {
      return null;
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

class XPBridgeApp extends StatefulWidget {
  const XPBridgeApp({super.key});

  @override
  State<XPBridgeApp> createState() => _XPBridgeAppState();
}

class _XPBridgeAppState extends State<XPBridgeApp> {
  late final AppState _state;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _state.loadApplications();
    _router = AppRouter(appState: _state).router;
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _state,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'XPBridge',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
