import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpbridge/routes/app_router.dart';
import 'package:xpbridge/theme/app_theme.dart';

import 'data/dummy_data.dart';
import 'models/ai_interview.dart';
import 'models/application.dart';
import 'models/event_log_entry.dart';
import 'models/guild.dart';
import 'models/guild_application.dart';
import 'models/skill_badge.dart';
import 'models/student_profile.dart';
import 'models/startup_profile.dart';
import 'models/startup_role.dart';
import 'services/ai_interview_service.dart';
import 'services/badge_service.dart';
import 'services/guild_service.dart';

enum UserRole { student, startup }

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserRole? _userRole;
  StudentProfile? _studentProfile;
  StartupProfile? _startupProfile;
  List<Application> _applications = List<Application>.from(
    DummyData.applications,
  );
  List<AiInterview> _aiInterviews = [];
  List<Guild> _guilds = [];
  List<GuildApplication> _guildApplications = [];
  List<SkillBadge> _skillBadges = [];
  List<EventLogEntry> _eventLog = [];
  bool _xpFeedOptOut = false;

  bool get isLoggedIn => _isLoggedIn;
  UserRole? get userRole => _userRole;
  StudentProfile? get studentProfile => _studentProfile;
  StartupProfile? get startupProfile => _startupProfile;
  List<Application> get applications => _applications;
  List<AiInterview> get aiInterviews => _aiInterviews;
  List<Guild> get guilds => _guilds;
  List<GuildApplication> get guildApplications => _guildApplications;
  List<SkillBadge> get skillBadges => _skillBadges;
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
    _refreshDerivedState();
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
    final storedInterviews = prefs.getString('ai_interviews');
    final storedGuilds = prefs.getString('guilds');
    final storedGuildApplications = prefs.getString('guild_applications');
    final storedBadges = prefs.getString('skill_badges');
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
    if (storedInterviews != null && storedInterviews.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedInterviews) as List<dynamic>;
        _aiInterviews = decoded
            .map(
              (item) => AiInterview.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        _aiInterviews = [];
      }
    }
    if (storedGuilds != null && storedGuilds.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedGuilds) as List<dynamic>;
        _guilds = decoded
            .map((item) => Guild.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        _guilds = GuildService.seededGuilds();
      }
    } else {
      _guilds = GuildService.seededGuilds();
    }
    if (storedGuildApplications != null && storedGuildApplications.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedGuildApplications) as List<dynamic>;
        _guildApplications = decoded
            .map(
              (item) => GuildApplication.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      } catch (_) {
        _guildApplications = GuildService.seededApplications();
      }
    } else {
      _guildApplications = GuildService.seededApplications();
    }
    if (storedBadges != null && storedBadges.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedBadges) as List<dynamic>;
        _skillBadges = decoded
            .map(
              (item) =>
                  SkillBadge.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        _skillBadges = [];
      }
    }
    _refreshDerivedState();
    notifyListeners();
  }

  Future<void> _persistApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'applications',
      jsonEncode(_applications.map((app) => app.toMap()).toList()),
    );
  }

  Future<void> _persistAiInterviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_interviews',
      jsonEncode(_aiInterviews.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistGuilds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'guilds',
      jsonEncode(_guilds.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistGuildApplications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'guild_applications',
      jsonEncode(_guildApplications.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistSkillBadges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'skill_badges',
      jsonEncode(_skillBadges.map((item) => item.toMap()).toList()),
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

  List<StudentProfile> get allStudents {
    final students = [...DummyData.students];
    final current = _studentProfile;
    if (current != null && students.every((item) => item.id != current.id)) {
      students.insert(0, current);
    }
    return students;
  }

  List<StartupProfile> get allStartups {
    final startups = [...DummyData.startups];
    final current = _startupProfile;
    if (current != null && startups.every((item) => item.id != current.id)) {
      startups.insert(0, current);
    }
    return startups;
  }

  StudentProfile? getStudentById(String studentId) {
    try {
      return allStudents.firstWhere((student) => student.id == studentId);
    } catch (_) {
      return null;
    }
  }

  StartupProfile? getStartupById(String startupId) {
    try {
      return allStartups.firstWhere((startup) => startup.id == startupId);
    } catch (_) {
      return null;
    }
  }

  StartupRole? getStartupRole(String startupId, String roleTitle) {
    final startup = getStartupById(startupId);
    if (startup == null) return null;
    try {
      return startup.openRoles.firstWhere((role) => role.title == roleTitle);
    } catch (_) {
      return null;
    }
  }

  Guild? getGuildById(String guildId) {
    try {
      return _guilds.firstWhere((guild) => guild.id == guildId);
    } catch (_) {
      return null;
    }
  }

  Guild? getGuildForStudent(String studentId) {
    try {
      return _guilds.firstWhere((guild) => guild.memberIds.contains(studentId));
    } catch (_) {
      return null;
    }
  }

  List<GuildApplication> getGuildApplicationsForStartup(String startupId) {
    return _guildApplications
        .where((application) => application.startupId == startupId)
        .toList();
  }

  List<GuildApplication> getGuildApplicationsForGuild(String guildId) {
    return _guildApplications
        .where((application) => application.guildId == guildId)
        .toList();
  }

  int getActiveGuildMissionCount(String guildId) {
    return _guildApplications.where((application) {
      return application.guildId == guildId &&
          application.status != ApplicationStatus.completed &&
          application.status != ApplicationStatus.rejected;
    }).length;
  }

  AiInterview? getInterviewById(String interviewId) {
    try {
      return _aiInterviews.firstWhere((item) => item.id == interviewId);
    } catch (_) {
      return null;
    }
  }

  AiInterview? getInterviewForApplication(String applicationId) {
    try {
      return _aiInterviews.firstWhere(
        (interview) => interview.applicationId == applicationId,
      );
    } catch (_) {
      return null;
    }
  }

  List<AiInterview> getInterviewsForStartup(String startupId) {
    return _aiInterviews
        .where((interview) => interview.startupId == startupId)
        .toList();
  }

  List<SkillBadge> getBadgesForStudent(String studentId) {
    return _skillBadges
        .where((badge) => badge.studentId == studentId)
        .toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  List<StudentProfile> getGuildMembers(String guildId) {
    final guild = getGuildById(guildId);
    if (guild == null) return [];
    return guild.memberIds
        .map(getStudentById)
        .whereType<StudentProfile>()
        .toList();
  }

  void _refreshDerivedState() {
    _recalculateStudentProgress();
    final previousBadgeIds = _skillBadges.map((badge) => badge.id).toSet();
    _skillBadges = BadgeService.issueEligibleBadges(
      students: allStudents,
      applications: _applications,
      guilds: _guilds,
      guildApplications: _guildApplications,
      existingBadges: _skillBadges,
    );
    final currentStudent = _studentProfile;
    if (currentStudent != null) {
      final newCurrentBadge = _skillBadges.firstWhere(
        (badge) =>
            badge.studentId == currentStudent.id &&
            !previousBadgeIds.contains(badge.id),
        orElse: () => const SkillBadge(
          id: '',
          studentId: '',
          title: '',
          description: '',
          issuedAt: DateTime(2000),
          badgeType: SkillBadgeType.level10Achieved,
          earnedFrom: '',
          verificationStatus: SkillBadgeVerificationStatus.pending,
          tokenIdOrReference: '',
        ),
      );
      if (newCurrentBadge.id.isNotEmpty) {
        _logEvent(
          'badge_issued',
          'Earned ${newCurrentBadge.title}',
          _firstName(currentStudent.name),
        );
      }
    }
    unawaited(_persistSkillBadges());
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
    final currentGuild = getGuildForStudent(profile.id);
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
    if (currentGuild != null) {
      xp += (currentGuild.collaborationXp * 0.35).round();
    }

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
    _refreshDerivedState();
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
    _refreshDerivedState();
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
    _refreshDerivedState();
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
    _refreshDerivedState();
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

  Future<AiInterview?> requestAiInterview(String applicationId) async {
    final existing = getInterviewForApplication(applicationId);
    if (existing != null) {
      return existing;
    }
    final application = getApplicationById(applicationId);
    if (application == null) return null;

    final interview = AiInterviewService.createInterview(
      application: application,
      student: getStudentById(application.studentId),
      startup: getStartupById(application.startupId),
    );
    _aiInterviews = [interview, ..._aiInterviews];
    _applications = _applications.map((app) {
      if (app.id == applicationId && app.status == ApplicationStatus.pending) {
        return app.copyWith(
          status: ApplicationStatus.interviewing,
          updatedAt: DateTime.now(),
        );
      }
      return app;
    }).toList();
    notifyListeners();
    await _persistAiInterviews();
    await _persistApplications();
    return interview;
  }

  Future<void> startAiInterview(String interviewId) async {
    _aiInterviews = _aiInterviews.map((interview) {
      if (interview.id == interviewId) {
        return interview.copyWith(status: AiInterviewStatus.inProgress);
      }
      return interview;
    }).toList();
    notifyListeners();
    await _persistAiInterviews();
  }

  Future<AiInterview?> submitAiInterview(
    String interviewId,
    List<AiInterviewResponse> responses,
  ) async {
    AiInterview? updatedInterview;
    _aiInterviews = _aiInterviews.map((interview) {
      if (interview.id == interviewId) {
        updatedInterview = AiInterviewService.evaluateInterview(
          interview,
          responses,
        );
        return updatedInterview!;
      }
      return interview;
    }).toList();
    notifyListeners();
    await _persistAiInterviews();
    return updatedInterview;
  }

  Future<Guild?> createGuild({
    required String name,
    required String description,
    List<String> skillTags = const [],
  }) async {
    final student = _studentProfile;
    if (student == null) return null;

    final existing = getGuildForStudent(student.id);
    if (existing != null) {
      await leaveGuild(existing.id, student.id);
    }

    final guild = GuildService.createGuild(
      name: name,
      description: description,
      owner: student,
      skillTags: skillTags,
    );
    _guilds = [guild, ..._guilds];
    _refreshDerivedState();
    notifyListeners();
    await _persistGuilds();
    return guild;
  }

  Future<void> joinGuild(String guildId, String studentId) async {
    final student = getStudentById(studentId);
    if (student == null) return;

    final existing = getGuildForStudent(studentId);
    if (existing != null && existing.id != guildId) {
      await leaveGuild(existing.id, studentId);
    }

    _guilds = _guilds.map((guild) {
      if (guild.id != guildId || guild.memberIds.contains(studentId)) {
        return guild;
      }
      final updatedGuild = guild.copyWith(
        memberIds: [...guild.memberIds, studentId],
      );
      return GuildService.mergeMemberSkills(updatedGuild, getGuildMembers(guildId)..add(student));
    }).toList();
    _refreshDerivedState();
    notifyListeners();
    await _persistGuilds();
  }

  Future<void> leaveGuild(String guildId, String studentId) async {
    _guilds = _guilds
        .map((guild) {
          if (guild.id != guildId) return guild;
          final remainingMembers = guild.memberIds
              .where((memberId) => memberId != studentId)
              .toList();
          if (remainingMembers.isEmpty) {
            return guild.copyWith(memberIds: const []);
          }
          return GuildService.mergeMemberSkills(
            guild.copyWith(
              ownerStudentId: guild.ownerStudentId == studentId
                  ? remainingMembers.first
                  : guild.ownerStudentId,
              memberIds: remainingMembers,
            ),
            remainingMembers
                .map(getStudentById)
                .whereType<StudentProfile>()
                .toList(),
          );
        })
        .where((guild) => guild.memberIds.isNotEmpty)
        .toList();
    _refreshDerivedState();
    notifyListeners();
    await _persistGuilds();
  }

  Future<GuildApplication?> submitGuildApplication({
    required String guildId,
    required String startupId,
    required String startupName,
    required String missionTitle,
    required String message,
  }) async {
    final exists = _guildApplications.any(
      (application) =>
          application.guildId == guildId &&
          application.missionTitle == missionTitle &&
          application.startupId == startupId &&
          application.status != ApplicationStatus.rejected,
    );
    if (exists) return null;

    final application = GuildService.createGuildApplication(
      guildId: guildId,
      startupId: startupId,
      startupName: startupName,
      missionTitle: missionTitle,
      message: message,
    );
    _guildApplications = [application, ..._guildApplications];
    _refreshDerivedState();
    notifyListeners();
    await _persistGuildApplications();
    return application;
  }

  Future<void> advanceGuildApplication(String guildApplicationId) async {
    _guildApplications = _guildApplications.map((application) {
      if (application.id == guildApplicationId) {
        return application.copyWith(
          status: GuildService.nextStatus(application.status),
          updatedAt: DateTime.now(),
        );
      }
      return application;
    }).toList();
    await _applyGuildRewards();
  }

  Future<void> completeGuildApplication(String guildApplicationId) async {
    _guildApplications = _guildApplications.map((application) {
      if (application.id == guildApplicationId) {
        return application.copyWith(
          status: ApplicationStatus.completed,
          updatedAt: DateTime.now(),
        );
      }
      return application;
    }).toList();
    await _applyGuildRewards();
  }

  Future<void> _applyGuildRewards() async {
    _guilds = _guilds.map((guild) {
      final completedForGuild = _guildApplications.where(
        (application) =>
            application.guildId == guild.id &&
            application.status == ApplicationStatus.completed,
      );
      final activeForGuild = _guildApplications.where(
        (application) =>
            application.guildId == guild.id &&
            application.status != ApplicationStatus.completed &&
            application.status != ApplicationStatus.rejected,
      );
      return guild.copyWith(
        collaborationXp:
            (completedForGuild.length * 120) + (activeForGuild.length * 35),
        completedTeamMissionsCount: completedForGuild.length,
      );
    }).toList();
    _refreshDerivedState();
    notifyListeners();
    await _persistGuildApplications();
    await _persistGuilds();
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
