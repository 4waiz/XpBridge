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
  bool _isGuestPreview = false;
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
  bool get isGuestPreview => _isGuestPreview;
  bool get _useDummyData => isPreviewingAsAdmin || _isGuestPreview;
  UserRole? get activeRole =>
      _adminPreviewRole ?? (_isGuestPreview ? UserRole.student : _userRole);
  bool get isStudent => activeRole == UserRole.student;
  bool get isStartup => activeRole == UserRole.startup;

  StudentProfile? get studentProfile {
    if (_isGuestPreview) return _guestStudentProfile;
    if (isPreviewingAsAdmin && isStudent) return _previewStudentProfile;
    return _studentProfile;
  }
  StartupProfile? get startupProfile => isPreviewingAsAdmin && isStartup
      ? _previewStartupProfile
      : _startupProfile;
  List<StudentProfile> get students =>
      _useDummyData ? _previewStudents : _students;
  List<StartupProfile> get startups =>
      _useDummyData ? _previewStartups : _startups;
  List<Mission> get missions =>
      _useDummyData ? _previewMissions : _missions;
  List<Application> get applications =>
      _useDummyData ? _previewApplications : _applications;
  List<AiInterview> get aiInterviews =>
      _useDummyData ? _previewAiInterviews : _aiInterviews;
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
    // If a returning user already completed onboarding but isn't logged in,
    // drop them into guest preview so they land on the demo dashboard instead
    // of the login wall. `refreshSession` will clear this flag if a live
    // Supabase session is found.
    if (_onboardingComplete) {
      _isGuestPreview = true;
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    _onboardingComplete = true;
    if (!_isLoggedIn) {
      _isGuestPreview = true;
    }
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
        debugPrint('[bootstrap] no Supabase session');
        _requiresAccountCompletion = false;
        _resetSessionState();
        return;
      }

      debugPrint('[bootstrap] session present (user=${user.id})');

      final profileRecord = await SupabaseService.ensureProfileForCurrentUser();
      if (profileRecord == null) {
        debugPrint(
          '[bootstrap] no profile row + no pending role -> requires account completion',
        );
        _errorMessage =
            'Pick Student or Startup to finish setting up your account.';
        _requiresAccountCompletion = true;
        _isLoggedIn = true; // Still logged in via Supabase Auth
        _resetSessionState(keepAuth: true);
        return;
      }

      _requiresAccountCompletion = false;
      _isLoggedIn = true;
      _adminPreviewRole = null;
      _isGuestPreview = false;
      final roleString = profileRecord['role'] as String? ?? 'student';
      _userRole = roleString == 'startup' ? UserRole.startup : UserRole.student;
      _isAdmin = profileRecord['is_admin'] as bool? ?? false;
      debugPrint('[bootstrap] role=$_userRole, isAdmin=$_isAdmin');

      final Future<Object?> profileFuture = _userRole == UserRole.student
          ? SupabaseService.getStudentProfile(user.id)
          : _userRole == UserRole.startup
              ? SupabaseService.getStartupProfile(user.id)
              : Future<Object?>.value(null);

      final results = await Future.wait<Object?>([
        profileFuture,
        SupabaseService.getStudents(),
        SupabaseService.getStartups(),
        SupabaseService.getMissions(),
      ]);

      if (_userRole == UserRole.student) {
        _studentProfile = results[0] as StudentProfile?;
      } else if (_userRole == UserRole.startup) {
        _startupProfile = results[0] as StartupProfile?;
      }
      _students = results[1] as List<StudentProfile>;
      _startups = results[2] as List<StartupProfile>;
      _missions = results[3] as List<Mission>;

      await _refreshCollections();
      debugPrint('[bootstrap] complete: isLoggedIn=true');
    } on XpServiceException catch (error) {
      debugPrint('[bootstrap] XpServiceException: ${error.message}');
      _errorMessage = error.message;
      // If the session exists but profile fetch genuinely fails, don't pin
      // the user to the splash — let the router send them to /signup so
      // they can try again or pick a role.
      if (SupabaseService.currentUser != null) {
        _requiresAccountCompletion = true;
        _isLoggedIn = true;
      }
    } catch (error, stack) {
      // Belt & braces: never leak an uncaught error out of bootstrap.
      debugPrint('[bootstrap] unexpected error: $error\n$stack');
      _errorMessage = 'Something went wrong while loading your account.';
      if (SupabaseService.currentUser != null) {
        _requiresAccountCompletion = true;
        _isLoggedIn = true;
      }
    } finally {
      _isBusy = false;
      if (markInitialized) {
        _isInitialized = true;
      }
      notifyListeners();
    }
  }

  Future<void> _refreshCollections({bool skipBaseCollections = true}) async {
    if (!skipBaseCollections) {
      final baseResults = await Future.wait<Object?>([
        SupabaseService.getStudents(),
        SupabaseService.getStartups(),
        SupabaseService.getMissions(),
      ]);
      _students = baseResults[0] as List<StudentProfile>;
      _startups = baseResults[1] as List<StartupProfile>;
      _missions = baseResults[2] as List<Mission>;
    }

    if (_isAdmin) {
      final results = await Future.wait<Object?>([
        SupabaseService.getAllApplications(),
        SupabaseService.getAllAiInterviews(),
      ]);
      _applications = results[0] as List<Application>;
      _aiInterviews = results[1] as List<AiInterview>;
    } else if (isStudent && _studentProfile != null) {
      final results = await Future.wait<Object?>([
        SupabaseService.getApplicationsForStudent(_studentProfile!.id),
        SupabaseService.getInterviewsForStudent(_studentProfile!.id),
      ]);
      _applications = results[0] as List<Application>;
      _aiInterviews = results[1] as List<AiInterview>;
    } else if (isStartup && _startupProfile != null) {
      final results = await Future.wait<Object?>([
        SupabaseService.getApplicationsForStartup(_startupProfile!.id),
        SupabaseService.getInterviewsForStartup(_startupProfile!.id),
      ]);
      _applications = results[0] as List<Application>;
      _aiInterviews = results[1] as List<AiInterview>;
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
    if (_onboardingComplete) {
      _isGuestPreview = true;
    }
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
    if (_isGuestPreview) return;
    _isBusy = true;
    notifyListeners();
    try {
      await SupabaseService.upsertStudentProfile(profile);
      _studentProfile = profile;
      await _refreshCollections(skipBaseCollections: false);
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
      await _refreshCollections(skipBaseCollections: false);
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
    if (_isGuestPreview) return;
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
    if (_isGuestPreview) return;
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
    if (_isGuestPreview) return;
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
    final updatedList = <AiInterview>[];
    for (final interview in _aiInterviews) {
      if (interview.id != interviewId) {
        updatedList.add(interview);
      } else {
        final updated = interview.copyWith(status: AiInterviewStatus.inProgress);
        await SupabaseService.updateAiInterview(updated);
        updatedList.add(updated);
      }
    }
    _aiInterviews = updatedList;
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

  static final StudentProfile _guestStudentProfile = StudentProfile(
    id: 'guest',
    name: 'Welcome to XPBridge!',
    email: 'guest@xpbridge.app',
    bio:
        'This is a read-only preview. Sign up to apply to missions, track applications, and chat with XPBridge AI.',
    education: 'Sign up to add your education',
    skills: const ['Flutter', 'React', 'Figma', 'Python'],
    availabilityHours: 10,
    createdAt: DateTime(2024, 1, 1),
    xpPoints: 1200,
    level: 4,
    missionsCompletedCount: 4,
  );
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

  void enterGuestPreview() {
    if (_isLoggedIn) return;
    if (_isGuestPreview) return;
    _isGuestPreview = true;
    notifyListeners();
  }

  void exitGuestPreview() {
    if (!_isGuestPreview) return;
    _isGuestPreview = false;
    notifyListeners();
  }

  /// Returns true if the caller may proceed with a write action. If the user
  /// is in guest preview, redirects them to `/login` and returns false so the
  /// caller can early-return.
  bool requireAuthOr(BuildContext context) {
    if (_isGuestPreview) {
      context.go('/login');
      return false;
    }
    return true;
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
  const XPBridgeApp({super.key, required this.appState});

  /// Pre-hydrated state built in `main()` so the first frame already
  /// reflects the real auth/session state (no `/login` flicker while an
  /// OAuth callback is being exchanged).
  final AppState appState;

  @override
  State<XPBridgeApp> createState() => _XPBridgeAppState();
}

class _XPBridgeAppState extends State<XPBridgeApp> {
  late final GoRouter _router;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _router = AppRouter(appState: widget.appState).router;
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      data,
    ) {
      // Only refresh on meaningful state changes to avoid race conditions
      // during OAuth callback processing.
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed) {
        widget.appState.refreshSession();
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
      notifier: widget.appState,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'XPBridge',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
