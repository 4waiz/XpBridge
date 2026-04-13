import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'data/dummy_data.dart';
import 'models/ai_interview.dart';
import 'models/application.dart';
import 'models/event_log_entry.dart';
import 'models/guild.dart';
import 'models/guild_application.dart';
import 'models/mission.dart';
import 'models/skill_badge.dart';
import 'models/student_profile.dart';
import 'models/startup_profile.dart';
import 'models/startup_role.dart';
import 'routes/app_router.dart';
import 'services/ai_interview_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

enum UserRole { student, startup }

class AppState extends ChangeNotifier {
  AppState();

  bool _isInitialized = false;
  bool _isBusy = false;
  bool _onboardingComplete = false;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  UserRole? _adminPreviewRole;
  bool _requiresAccountCompletion = false;
  bool _xpFeedOptOut = false;
  String? _errorMessage;
  UserRole? _userRole;

  StudentProfile? _studentProfile;
  StartupProfile? _startupProfile;

  List<StudentProfile> _students = [];
  List<StartupProfile> _startups = [];
  List<Mission> _missions = [];
  List<Application> _applications = [];
  List<AiInterview> _aiInterviews = [];

  // Compatibility surfaces kept for older screens that still compile in-tree.
  List<Guild> _guilds = [];
  List<GuildApplication> _guildApplications = [];
  List<SkillBadge> _skillBadges = [];
  List<EventLogEntry> _eventLog = [];

  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  bool get onboardingComplete => _onboardingComplete;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  bool get requiresAccountCompletion => _requiresAccountCompletion;
  bool get xpFeedOptOut => _xpFeedOptOut;
  String? get errorMessage => _errorMessage;
  UserRole? get userRole => _userRole;
  bool get isPreviewingAsAdmin => _isAdmin && _adminPreviewRole != null;
  UserRole? get activeRole => _adminPreviewRole ?? _userRole;
  bool get isStudent => activeRole == UserRole.student;
  bool get isStartup => activeRole == UserRole.startup;

  StudentProfile? get studentProfile => isPreviewingAsAdmin && isStudent
      ? _previewStudentProfile
      : _studentProfile;
  StartupProfile? get startupProfile => isPreviewingAsAdmin && isStartup
      ? _previewStartupProfile
      : _startupProfile;
  List<StudentProfile> get students =>
      isPreviewingAsAdmin ? _previewStudents : _students;
  List<StartupProfile> get startups =>
      isPreviewingAsAdmin ? _previewStartups : _startups;
  List<Mission> get missions =>
      isPreviewingAsAdmin ? _previewMissions : _missions;
  List<Application> get applications =>
      isPreviewingAsAdmin ? _previewApplications : _applications;
  List<AiInterview> get aiInterviews =>
      isPreviewingAsAdmin ? _previewAiInterviews : _aiInterviews;
  List<Guild> get guilds => _guilds;
  List<GuildApplication> get guildApplications => _guildApplications;
  List<SkillBadge> get skillBadges => _skillBadges;
  List<EventLogEntry> get eventLog => _eventLog;

  bool get aiFeaturesEnabled => AppConfig.instance.aiFeaturesEnabled;

  bool get needsProfileSetup {
    if (!_isLoggedIn) return false;
    if (_isAdmin) return false;
    if (isStudent) return !_isStudentProfileComplete(_studentProfile);
    if (isStartup) return !_isStartupProfileComplete(_startupProfile);
    return false;
  }

  String get defaultAuthenticatedLocation {
    if (isPreviewingAsAdmin) {
      return isStudent ? '/student/dashboard' : '/startup/dashboard';
    }
    if (needsProfileSetup) {
      return isStudent ? '/student/setup' : '/startup/setup';
    }
    return isStudent ? '/student/dashboard' : '/startup/dashboard';
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadOnboardingPreference();
    await refreshSession(markInitialized: true);
  }

  Future<void> _loadOnboardingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<bool> loadUserSession() async {
    await initialize();
    return _isLoggedIn;
  }

  void login({required UserRole role}) {
    _isLoggedIn = true;
    _userRole = role;
    notifyListeners();
  }

  void setUserRole(UserRole role) {
    _userRole = role;
    notifyListeners();
  }

  void saveStudentProfile(StudentProfile profile) {
    _studentProfile = profile;
    _upsertStudent(profile);
    notifyListeners();
  }

  void saveStartupProfile(StartupProfile profile) {
    _startupProfile = profile;
    _upsertStartup(profile);
    notifyListeners();
  }

  Future<void> refreshSession({bool markInitialized = false}) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        _requiresAccountCompletion = false;
        _resetSessionState();
        return;
      }

      final profileRecord = await SupabaseService.ensureProfileForCurrentUser();
      if (profileRecord == null) {
        _errorMessage =
            'Finish account setup for this Google account by choosing Student or Startup.';
        _requiresAccountCompletion = true;
        _isLoggedIn = true; // Still logged in via Supabase Auth
        _resetSessionState(keepAuth: true);
        return;
      }

      _requiresAccountCompletion = false;
      _isLoggedIn = true;
      _adminPreviewRole = null;
      final roleString = profileRecord['role'] as String? ?? 'student';
      _userRole = roleString == 'startup' ? UserRole.startup : UserRole.student;
      _isAdmin = profileRecord['is_admin'] as bool? ?? false;

      _studentProfile = _userRole == UserRole.student
          ? await SupabaseService.getStudentProfile(user.id)
          : null;
      _startupProfile = _userRole == UserRole.startup
          ? await SupabaseService.getStartupProfile(user.id)
          : null;

      await _refreshCollections();
    } on XpServiceException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isBusy = false;
      if (markInitialized) {
        _isInitialized = true;
      }
      notifyListeners();
    }
  }

  Future<void> _refreshCollections() async {
    _students = await SupabaseService.getStudents();
    _startups = await SupabaseService.getStartups();
    _missions = await SupabaseService.getMissions();

    if (_isAdmin) {
      _applications = await SupabaseService.getAllApplications();
      _aiInterviews = await SupabaseService.getAllAiInterviews();
    } else if (isStudent && _studentProfile != null) {
      _applications = await SupabaseService.getApplicationsForStudent(
        _studentProfile!.id,
      );
      _aiInterviews = await SupabaseService.getInterviewsForStudent(
        _studentProfile!.id,
      );
    } else if (isStartup && _startupProfile != null) {
      _applications = await SupabaseService.getApplicationsForStartup(
        _startupProfile!.id,
      );
      _aiInterviews = await SupabaseService.getInterviewsForStartup(
        _startupProfile!.id,
      );
      _startupProfile = _startupProfile!.copyWith(
        openRoles: _missions
            .where((mission) => mission.startupId == _startupProfile!.id)
            .map((mission) => mission.toStartupRole())
            .toList(),
      );
      _upsertStartup(_startupProfile!);
    }

    if (_studentProfile != null) {
      final refreshedStudent = _students.cast<StudentProfile?>().firstWhere(
        (item) => item?.id == _studentProfile!.id,
        orElse: () => _studentProfile,
      );
      _studentProfile = refreshedStudent;
    }

    if (_startupProfile != null) {
      final refreshedStartup = _startups.cast<StartupProfile?>().firstWhere(
        (item) => item?.id == _startupProfile!.id,
        orElse: () => _startupProfile,
      );
      _startupProfile = refreshedStartup?.copyWith(
        openRoles: _missions
            .where((mission) => mission.startupId == _startupProfile!.id)
            .map((mission) => mission.toStartupRole())
            .toList(),
      );
    }
  }

  Future<void> loadApplications() async {
    if (!_isLoggedIn) {
      _applications = [];
      _aiInterviews = [];
      notifyListeners();
      return;
    }
    await refreshSession();
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    _requiresAccountCompletion = false;
    _resetSessionState();
    notifyListeners();
  }

  Future<void> setFeedOptOut(bool value) async {
    _xpFeedOptOut = value;
    notifyListeners();
  }

  Future<void> deleteAccountWithPassword(String password) async {
    _isBusy = true;
    notifyListeners();
    try {
      await SupabaseService.deleteAccountWithPassword(password);
      _requiresAccountCompletion = false;
      _resetSessionState();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  List<StudentProfile> get allStudents {
    final current = studentProfile;
    final source = students;
    if (current == null) return List<StudentProfile>.from(source);
    return source.any((item) => item.id == current.id)
        ? List<StudentProfile>.from(source)
        : [current, ...source];
  }

  List<StartupProfile> get allStartups {
    final current = startupProfile;
    final source = startups;
    if (current == null) return List<StartupProfile>.from(source);
    return source.any((item) => item.id == current.id)
        ? List<StartupProfile>.from(source)
        : [current, ...source];
  }

  StudentProfile? getStudentById(String studentId) {
    for (final student in allStudents) {
      if (student.id == studentId) return student;
    }
    return null;
  }

  StartupProfile? getStartupById(String startupId) {
    for (final startup in allStartups) {
      if (startup.id == startupId) return startup;
    }
    return null;
  }

  Mission? getMissionById(String missionId) {
    for (final mission in _missions) {
      if (mission.id == missionId) return mission;
    }
    return null;
  }

  StartupRole? getStartupRole(String startupId, String roleTitle) {
    final startup = getStartupById(startupId);
    if (startup == null) return null;
    for (final role in startup.openRoles) {
      if (role.title == roleTitle) return role;
    }
    return null;
  }

  Guild? getGuildById(String guildId) => null;
  Guild? getGuildForStudent(String studentId) => null;
  List<GuildApplication> getGuildApplicationsForStartup(String startupId) => [];
  List<GuildApplication> getGuildApplicationsForGuild(String guildId) => [];
  int getActiveGuildMissionCount(String guildId) => 0;
  List<StudentProfile> getGuildMembers(String guildId) => [];

  AiInterview? getInterviewById(String interviewId) {
    for (final interview in _aiInterviews) {
      if (interview.id == interviewId) return interview;
    }
    return null;
  }

  AiInterview? getInterviewForApplication(String applicationId) {
    for (final interview in _aiInterviews) {
      if (interview.applicationId == applicationId) return interview;
    }
    return null;
  }

  List<AiInterview> getInterviewsForStartup(String startupId) {
    return _aiInterviews
        .where((interview) => interview.startupId == startupId)
        .toList();
  }

  List<SkillBadge> getBadgesForStudent(String studentId) => [];

  List<Application> getApplicationsForStudent(String studentId) {
    return applications
        .where((application) => application.studentId == studentId)
        .toList();
  }

  List<Application> getApplicationsForStartup(String startupId) {
    return applications
        .where((application) => application.startupId == startupId)
        .toList();
  }

  Application? getApplicationById(String applicationId) {
    for (final application in _applications) {
      if (application.id == applicationId) return application;
    }
    return null;
  }

  Future<void> persistStudentProfile(StudentProfile profile) async {
    _isBusy = true;
    notifyListeners();
    try {
      await SupabaseService.upsertStudentProfile(profile);
      _studentProfile = profile;
      await _refreshCollections();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> persistStartupProfile(StartupProfile profile) async {
    _isBusy = true;
    notifyListeners();
    try {
      await SupabaseService.upsertStartupProfile(profile);
      _startupProfile = profile;
      await _refreshCollections();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<Mission> createMission(StartupRole role) async {
    final startup = _startupProfile;
    if (startup == null) {
      throw const XpServiceException('Complete your startup profile first.');
    }
    final mission = await SupabaseService.createMissionFromRole(
      startupId: startup.id,
      role: role,
      requiredSkills: startup.requiredSkills,
    );
    _missions = [
      mission.copyWith(startupName: startup.companyName),
      ..._missions,
    ];
    _startupProfile = startup.copyWith(openRoles: [...startup.openRoles, role]);
    _upsertStartup(_startupProfile!);
    notifyListeners();
    return mission;
  }

  Future<void> deleteMission(String missionId) async {
    await SupabaseService.deleteMission(missionId);
    _missions = _missions.where((mission) => mission.id != missionId).toList();
    if (_startupProfile != null) {
      _startupProfile = _startupProfile!.copyWith(
        openRoles: _missions
            .where((mission) => mission.startupId == _startupProfile!.id)
            .map((mission) => mission.toStartupRole())
            .toList(),
      );
    }
    notifyListeners();
  }

  Future<void> addApplication(Application application) async {
    final duplicate = _applications.any(
      (existing) =>
          existing.studentId == application.studentId &&
          existing.missionId == application.missionId &&
          existing.missionId != null,
    );
    if (duplicate) {
      throw const XpServiceException('You already applied to this mission.');
    }

    final saved = await SupabaseService.submitApplication(application);
    _applications = [saved, ..._applications];
    await _syncStudentProgress(saved.studentId);
    notifyListeners();
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    await SupabaseService.updateApplicationStatus(applicationId, status.name);
    _applications = _applications.map((application) {
      if (application.id != applicationId) return application;
      return application.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        completedAt: status == ApplicationStatus.completed
            ? DateTime.now()
            : application.completedAt,
      );
    }).toList();
    final updated = getApplicationById(applicationId);
    if (updated != null) {
      await _syncStudentProgress(updated.studentId);
    }
    notifyListeners();
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
    await SupabaseService.updateApplicationReflection(applicationId, {
      'reflection_did': did,
      'reflection_learned': learned,
      'skills_practiced': skillsPracticed,
      'hours_spent': hoursSpent,
      'deliverable_url': deliverableUrl,
      'deliverable_type': deliverableType,
    });
    _applications = _applications.map((application) {
      if (application.id != applicationId) return application;
      return application.copyWith(
        reflectionDid: did ?? application.reflectionDid,
        reflectionLearned: learned ?? application.reflectionLearned,
        skillsPracticed: skillsPracticed ?? application.skillsPracticed,
        hoursSpent: hoursSpent ?? application.hoursSpent,
        deliverableUrl: deliverableUrl ?? application.deliverableUrl,
        deliverableType: deliverableType ?? application.deliverableType,
        updatedAt: DateTime.now(),
      );
    }).toList();
    final updated = getApplicationById(applicationId);
    if (updated != null) {
      await _syncStudentProgress(updated.studentId);
    }
    notifyListeners();
  }

  Future<void> saveMentorFeedback(
    String applicationId, {
    int? rating,
    String? feedback,
    List<String>? strengths,
    List<String>? growthAreas,
    List<String>? endorsedSkills,
  }) async {
    await SupabaseService.updateApplicationFeedback(applicationId, {
      'mentor_rating': rating,
      'mentor_feedback_text': feedback,
      'strengths': strengths,
      'growth_areas': growthAreas,
      'endorsed_skills': endorsedSkills,
    });
    _applications = _applications.map((application) {
      if (application.id != applicationId) return application;
      return application.copyWith(
        mentorRating: rating ?? application.mentorRating,
        mentorFeedbackText: feedback ?? application.mentorFeedbackText,
        strengths: strengths ?? application.strengths,
        growthAreas: growthAreas ?? application.growthAreas,
        endorsedSkills: endorsedSkills ?? application.endorsedSkills,
        feedbackAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
    final updated = getApplicationById(applicationId);
    if (updated != null) {
      await _syncStudentProgress(updated.studentId);
    }
    notifyListeners();
  }

  Future<AiInterview?> requestAiInterview(String applicationId) async {
    final existing = getInterviewForApplication(applicationId);
    if (existing != null) return existing;

    final application = getApplicationById(applicationId);
    if (application == null) return null;

    final interview = AiInterviewService.createInterview(
      application: application,
      student: getStudentById(application.studentId),
      startup: getStartupById(application.startupId),
    );
    final saved = await SupabaseService.createAiInterview(interview);
    _aiInterviews = [saved, ..._aiInterviews];
    if (application.status == ApplicationStatus.pending) {
      await updateApplicationStatus(
        applicationId,
        ApplicationStatus.interviewing,
      );
    }
    notifyListeners();
    return saved;
  }

  Future<void> startAiInterview(String interviewId) async {
    _aiInterviews = _aiInterviews.map((interview) {
      if (interview.id != interviewId) return interview;
      final updated = interview.copyWith(status: AiInterviewStatus.inProgress);
      SupabaseService.updateAiInterview(updated);
      return updated;
    }).toList();
    notifyListeners();
  }

  Future<AiInterview?> submitAiInterview(
    String interviewId,
    List<AiInterviewResponse> responses,
  ) async {
    AiInterview? updatedInterview;
    _aiInterviews = _aiInterviews.map((interview) {
      if (interview.id != interviewId) return interview;
      updatedInterview = AiInterviewService.evaluateInterview(
        interview,
        responses,
      );
      return updatedInterview!;
    }).toList();
    if (updatedInterview != null) {
      await SupabaseService.updateAiInterview(updatedInterview!);
    }
    notifyListeners();
    return updatedInterview;
  }

  Future<Guild?> createGuild({
    required String name,
    required String description,
    List<String> skillTags = const [],
  }) async {
    return null;
  }

  Future<void> joinGuild(String guildId, String studentId) async {}
  Future<void> leaveGuild(String guildId, String studentId) async {}

  Future<GuildApplication?> submitGuildApplication({
    required String guildId,
    required String startupId,
    required String startupName,
    required String missionTitle,
    required String message,
  }) async {
    return null;
  }

  Future<void> advanceGuildApplication(String guildApplicationId) async {}
  Future<void> completeGuildApplication(String guildApplicationId) async {}

  Future<void> _syncStudentProgress(String studentId) async {
    final profile = getStudentById(studentId);
    if (profile == null) return;
    final apps = await SupabaseService.getApplicationsForStudentAdmin(
      studentId,
    );
    final completed = apps
        .where(
          (application) => application.status == ApplicationStatus.completed,
        )
        .toList();
    final reflected = completed.where((application) {
      return (application.reflectionDid?.isNotEmpty ?? false) ||
          (application.reflectionLearned?.isNotEmpty ?? false);
    }).length;
    final reviewed = completed.where((application) {
      return application.mentorRating != null ||
          (application.mentorFeedbackText?.isNotEmpty ?? false);
    }).length;

    final xp = (completed.length * 120) + (reflected * 20) + (reviewed * 30);
    final level = _levelForXp(xp);
    final updated = profile.copyWith(
      xpPoints: xp,
      level: level,
      missionsCompletedCount: completed.length,
    );

    await SupabaseService.updateProfile(
      id: studentId,
      data: {
        'xp_points': xp,
        'level': level,
        'missions_completed_count': completed.length,
      },
    );

    _upsertStudent(updated);
    if (_studentProfile?.id == studentId) {
      _studentProfile = updated;
    }
  }

  int _levelForXp(int xp) {
    if (xp >= 6000) return 10;
    if (xp >= 4800) return 9;
    if (xp >= 3800) return 8;
    if (xp >= 3000) return 7;
    if (xp >= 2200) return 6;
    if (xp >= 1500) return 5;
    if (xp >= 900) return 4;
    if (xp >= 500) return 3;
    if (xp >= 200) return 2;
    return 1;
  }

  bool _isStudentProfileComplete(StudentProfile? profile) {
    if (profile == null) return false;
    return profile.name.trim().isNotEmpty && profile.skills.length >= 2;
  }

  bool _isStartupProfileComplete(StartupProfile? profile) {
    if (profile == null) return false;
    return profile.companyName.trim().isNotEmpty &&
        profile.description.trim().isNotEmpty &&
        profile.industry.trim().isNotEmpty &&
        profile.requiredSkills.length >= 2;
  }

  void _upsertStudent(StudentProfile profile) {
    _students = [profile, ..._students.where((item) => item.id != profile.id)];
  }

  void _upsertStartup(StartupProfile profile) {
    _startups = [profile, ..._startups.where((item) => item.id != profile.id)];
  }

  void _resetSessionState({bool keepAuth = false}) {
    if (!keepAuth) {
      _isLoggedIn = false;
      _userRole = null;
    }
    _isAdmin = false;
    _adminPreviewRole = null;
    _studentProfile = null;
    _startupProfile = null;
    _students = [];
    _startups = [];
    _missions = [];
    _applications = [];
    _aiInterviews = [];
    _guilds = [];
    _guildApplications = [];
    _skillBadges = [];
    _eventLog = [];
  }

  StudentProfile get _previewStudentProfile => _previewStudents.first;
  StartupProfile get _previewStartupProfile => _previewStartups.first;
  List<StudentProfile> get _previewStudents => DummyData.students;
  List<StartupProfile> get _previewStartups => DummyData.startups;
  List<Mission> get _previewMissions => [
    for (final startup in DummyData.startups)
      for (var i = 0; i < startup.openRoles.length; i++)
        Mission(
          id: 'demo_${startup.id}_$i',
          startupId: startup.id,
          startupName: startup.companyName,
          title: startup.openRoles[i].title,
          description:
              startup.openRoles[i].description ??
              startup.openRoles[i].learningOutcome,
          commitment: startup.openRoles[i].commitment,
          estimatedHours: startup.openRoles[i].estimatedHours,
          durationWeeks: startup.openRoles[i].durationWeeks,
          learningOutcome: startup.openRoles[i].learningOutcome,
          requiredSkills: startup.requiredSkills,
          status: 'open',
          createdAt: startup.createdAt,
          websiteUrl: startup.websiteUrl,
          logoUrl: startup.logoUrl,
          industry: startup.industry,
          teamMissionConfig: startup.openRoles[i].teamMissionConfig,
        ),
  ];
  List<Application> get _previewApplications => DummyData.applications;
  List<AiInterview> get _previewAiInterviews => const [];

  void enterAdminPreview(UserRole role) {
    if (!_isAdmin) return;
    _adminPreviewRole = role;
    notifyListeners();
  }

  void exitAdminPreview() {
    if (_adminPreviewRole == null) return;
    _adminPreviewRole = null;
    notifyListeners();
  }

  @visibleForTesting
  void debugSeed({
    required UserRole role,
    StudentProfile? studentProfile,
    StartupProfile? startupProfile,
    List<StudentProfile> students = const [],
    List<StartupProfile> startups = const [],
    List<Mission> missions = const [],
    List<Application> applications = const [],
    List<AiInterview> aiInterviews = const [],
    bool isAdmin = false,
  }) {
    _isInitialized = true;
    _isLoggedIn = true;
    _userRole = role;
    _studentProfile = studentProfile;
    _startupProfile = startupProfile;
    _students = students;
    _startups = startups;
    _missions = missions;
    _applications = applications;
    _aiInterviews = aiInterviews;
    _isAdmin = isAdmin;
    notifyListeners();
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _state.initialize();
    _router = AppRouter(appState: _state).router;
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      data,
    ) {
      // Only refresh on meaningful state changes to avoid race conditions
      // during OAuth callback processing.
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed) {
        _state.refreshSession();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
