import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/ai_interview.dart';
import '../models/application.dart';
import '../models/mission.dart';
import '../models/student_profile.dart';
import '../models/startup_profile.dart';
import '../models/startup_role.dart';

class XpServiceException implements Exception {
  const XpServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SupabaseService {
  static final client = Supabase.instance.client;
  static const _pendingOAuthRoleKey = 'pending_oauth_role';

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 20));
    } on PostgrestException catch (error) {
      throw XpServiceException(error.message);
    } on AuthException catch (error) {
      throw XpServiceException(error.message);
    } on StorageException catch (error) {
      throw XpServiceException(error.message);
    } catch (error) {
      if (error is XpServiceException) rethrow;
      throw XpServiceException('Unexpected network error ($error). Please try again.');
    }
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _run(() async {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const XpServiceException('Could not create your account.');
      }

      final authenticatedUser = client.auth.currentUser;
      if (authenticatedUser == null || authenticatedUser.id != response.user!.id) {
        throw const XpServiceException(
          'Account created. Verify your email first, then log in to finish setup.',
        );
      }

      await client.from('profiles').upsert({
        'id': response.user!.id,
        'name': role == 'student' ? name : null,
        'company_name': role == 'startup' ? name : null,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });

      return response;
    });
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _run(
      () => client.auth.signInWithPassword(email: email, password: password),
    );
  }

  static Future<void> signInWithGoogle({String? role}) {
    final redirectTo = kIsWeb
        ? '${Uri.base.origin}/login'
        : 'io.supabase.xpbridge://login-callback';

    return _run(() async {
      final prefs = await SharedPreferences.getInstance();
      if (role == null) {
        await prefs.remove(_pendingOAuthRoleKey);
      } else {
        await prefs.setString(_pendingOAuthRoleKey, role);
      }

      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
    });
  }

  static Future<void> signOut() {
    return _run(client.auth.signOut);
  }

  static Future<Map<String, dynamic>?> getCurrentProfileRecord() async {
    final user = currentUser;
    if (user == null) return null;

    return _run(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return Map<String, dynamic>.from(response);
    });
  }

  static Future<Map<String, dynamic>?> ensureProfileForCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    final existingProfile = await getCurrentProfileRecord();
    if (existingProfile != null) {
      await _clearPendingOAuthRole();
      return existingProfile;
    }

    final prefs = await SharedPreferences.getInstance();
    final pendingRole = prefs.getString(_pendingOAuthRoleKey);
    if (pendingRole != 'student' && pendingRole != 'startup') {
      return null;
    }

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw const XpServiceException('Google account is missing an email.');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fallbackName = email.split('@').first;
    final displayName =
        (metadata['full_name'] ??
                metadata['name'] ??
                metadata['user_name'] ??
                fallbackName)
            .toString()
            .trim();

    final profile = <String, dynamic>{
      'id': user.id,
      'email': email,
      'role': pendingRole,
      'name': pendingRole == 'startup' ? displayName : displayName,
      'company_name': pendingRole == 'startup' ? displayName : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    await client.from('profiles').upsert(profile);
    await _clearPendingOAuthRole();
    return profile;
  }

  static Future<Map<String, dynamic>> completeOAuthProfile({
    required String role,
    String? name,
  }) async {
    return _run(() async {
      final user = currentUser;
      if (user == null) {
        throw const XpServiceException('No authenticated Google user found.');
      }

      final email = user.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        throw const XpServiceException('Google account is missing an email.');
      }

      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final fallbackName = email.split('@').first;
      final displayName =
          (name?.trim().isNotEmpty == true
                  ? name!.trim()
                  : metadata['full_name'] ??
                      metadata['name'] ??
                      metadata['user_name'] ??
                      fallbackName)
              .toString()
              .trim();

      final profile = <String, dynamic>{
        'id': user.id,
        'email': email,
        'role': role,
        'name': displayName,
        'company_name': role == 'startup' ? displayName : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      await client.from('profiles').upsert(profile);
      await _clearPendingOAuthRole();
      return profile;
    });
  }

  static Future<void> _clearPendingOAuthRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOAuthRoleKey);
  }

  static Future<StudentProfile?> getStudentProfile(String id) async {
    return _run(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .eq('role', 'student')
          .maybeSingle();
      if (response == null) return null;
      return StudentProfile.fromMap(Map<String, dynamic>.from(response));
    });
  }

  static Future<StartupProfile?> getStartupProfile(String id) async {
    return _run(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .eq('role', 'startup')
          .maybeSingle();
      if (response == null) return null;
      return StartupProfile.fromMap(Map<String, dynamic>.from(response));
    });
  }

  static Future<List<StudentProfile>> getStudents() async {
    return _run(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('role', 'student')
          .order('xp_points', ascending: false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(StudentProfile.fromMap)
          .toList();
    });
  }

  static Future<List<StartupProfile>> getStartups() async {
    return _run(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('role', 'startup')
          .order('created_at', ascending: false);
      final startups = List<Map<String, dynamic>>.from(response)
          .map(StartupProfile.fromMap)
          .toList();

      final missions = await getMissions(includeClosed: true);
      return startups
          .map((startup) {
            final roles = missions
                .where((mission) => mission.startupId == startup.id)
                .map((mission) => mission.toStartupRole())
                .toList();
            return startup.copyWith(openRoles: roles);
          })
          .toList();
    });
  }

  static Future<void> upsertStudentProfile(StudentProfile profile) {
    return _run(() {
      return client.from('profiles').upsert({
        'id': profile.id,
        'role': 'student',
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'bio': profile.bio,
        'education': profile.education,
        'skills': profile.skills,
        'availability_hours': profile.availabilityHours,
        'portfolio_url': profile.portfolioUrl,
        'github_url': profile.githubUrl,
        'resume_url': profile.resumeUrl,
        'resume_file_name': profile.resumeFileName,
        'resume_mime_type': profile.resumeMimeType,
        'profile_image_url': profile.profileImageUrl,
        'xp_points': profile.xpPoints,
        'level': profile.level,
        'missions_completed_count': profile.missionsCompletedCount,
        'created_at': profile.createdAt.toIso8601String(),
      });
    });
  }

  static Future<void> upsertStartupProfile(StartupProfile profile) {
    return _run(() {
      return client.from('profiles').upsert({
        'id': profile.id,
        'role': 'startup',
        'company_name': profile.companyName,
        'name': profile.companyName,
        'email': profile.email,
        'phone': profile.phone,
        'bio': profile.description,
        'description': profile.description,
        'industry': profile.industry,
        'required_skills': profile.requiredSkills,
        'website_url': profile.websiteUrl,
        'logo_url': profile.logoUrl,
        'project_details': profile.projectDetails,
        'created_at': profile.createdAt.toIso8601String(),
      });
    });
  }

  static Future<void> updateProfile({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return _run(() => client.from('profiles').update(data).eq('id', id));
  }

  static Future<List<Mission>> getMissions({bool includeClosed = false}) async {
    return _run(() async {
      final missionResponse = includeClosed
          ? await client
                .from('missions')
                .select()
                .order('created_at', ascending: false)
          : await client
                .from('missions')
                .select()
                .eq('status', 'open')
                .order('created_at', ascending: false);
      final startupResponse = await client
          .from('profiles')
          .select()
          .eq('role', 'startup');
      final startups = {
        for (final item in List<Map<String, dynamic>>.from(startupResponse))
          item['id'] as String: item,
      };

      return List<Map<String, dynamic>>.from(missionResponse).map((item) {
        final startup = startups[item['startup_id']];
        return Mission.fromMap(
          item,
          startupName:
              (startup?['company_name'] ?? startup?['name']) as String?,
          websiteUrl: startup?['website_url'] as String?,
          logoUrl: startup?['logo_url'] as String?,
          industry: startup?['industry'] as String?,
        );
      }).toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> missionsStream() {
    return client.from('missions').stream(primaryKey: ['id']);
  }

  static Stream<List<Map<String, dynamic>>> studentsStream() {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'student');
  }

  static Future<Mission> createMissionFromRole({
    required String startupId,
    required StartupRole role,
    List<String> requiredSkills = const [],
  }) {
    return _run(() async {
      final response = await client
          .from('missions')
          .insert({
            'startup_id': startupId,
            'title': role.title,
            'description': role.description ?? role.learningOutcome,
            'commitment': role.commitment,
            'estimated_hours': role.estimatedHours,
            'duration_weeks': role.durationWeeks,
            'learning_outcome': role.learningOutcome,
            'required_skills': requiredSkills,
            'status': 'open',
            'team_config': role.teamMissionConfig?.toMap(),
          })
          .select()
          .single();
      return Mission.fromMap(Map<String, dynamic>.from(response));
    });
  }

  static Future<void> createMission(Map<String, dynamic> data) {
    return _run(() => client.from('missions').insert(data));
  }

  static Future<void> updateMission(Mission mission) {
    return _run(() {
      return client.from('missions').update({
        'title': mission.title,
        'description': mission.description,
        'commitment': mission.commitment,
        'estimated_hours': mission.estimatedHours,
        'duration_weeks': mission.durationWeeks,
        'learning_outcome': mission.learningOutcome,
        'required_skills': mission.requiredSkills,
        'status': mission.status,
        'team_config': mission.teamMissionConfig?.toMap(),
      }).eq('id', mission.id);
    });
  }

  static Future<void> deleteMission(String missionId) {
    return _run(() => client.from('missions').delete().eq('id', missionId));
  }

  static Future<Application> submitApplication(Application app) {
    return _run(() async {
      final response = await client
          .from('applications')
          .insert(app.toSupabaseMap())
          .select()
          .single();
      return Application.fromMap(Map<String, dynamic>.from(response));
    });
  }

  static Stream<List<Map<String, dynamic>>> applicationsStreamForStartup(
    String startupId,
  ) {
    return client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('startup_id', startupId)
        .order('applied_at', ascending: false);
  }

  static Stream<List<Map<String, dynamic>>> applicationsStreamForStudent(
    String studentId,
  ) {
    return client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('applied_at', ascending: false);
  }

  static Future<List<Application>> getApplicationsForStudent(
    String studentId,
  ) async {
    return _run(() async {
      final response = await client
          .from('applications')
          .select()
          .eq('student_id', studentId)
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(Application.fromMap)
          .toList();
    });
  }

  static Future<List<Application>> getApplicationsForStartup(
    String startupId,
  ) async {
    return _run(() async {
      final response = await client
          .from('applications')
          .select()
          .eq('startup_id', startupId)
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(Application.fromMap)
          .toList();
    });
  }

  static Future<List<Application>> getApplicationsForStudentAdmin(
    String studentId,
  ) {
    return getApplicationsForStudent(studentId);
  }

  static Future<List<Application>> getAllApplications() async {
    return _run(() async {
      final response = await client
          .from('applications')
          .select()
          .order('applied_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(Application.fromMap)
          .toList();
    });
  }

  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) {
    return _run(() {
      return client.from('applications').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'completed')
          'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', applicationId);
    });
  }

  static Future<void> updateApplicationReflection(
    String applicationId,
    Map<String, dynamic> reflectionData,
  ) {
    return _run(() {
      return client
          .from('applications')
          .update({
            ...reflectionData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
    });
  }

  static Future<void> updateApplicationFeedback(
    String applicationId,
    Map<String, dynamic> feedbackData,
  ) {
    return _run(() {
      return client
          .from('applications')
          .update({
            ...feedbackData,
            'feedback_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
    });
  }

  static Future<List<AiInterview>> getInterviewsForStudent(
    String studentId,
  ) async {
    return _run(() async {
      final response = await client
          .from('ai_interviews')
          .select()
          .eq('student_id', studentId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(AiInterview.fromMap)
          .toList();
    });
  }

  static Future<List<AiInterview>> getInterviewsForStartup(
    String startupId,
  ) async {
    return _run(() async {
      final response = await client
          .from('ai_interviews')
          .select()
          .eq('startup_id', startupId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response)
          .map(AiInterview.fromMap)
          .toList();
    });
  }

  static Future<AiInterview> createAiInterview(AiInterview interview) {
    return _run(() async {
      final response = await client
          .from('ai_interviews')
          .insert({
            'application_id': interview.applicationId,
            'mission_id': interview.missionId,
            'student_id': interview.studentId,
            'startup_id': interview.startupId,
            'questions': interview.questions,
            'responses': interview.responses.map((item) => item.toMap()).toList(),
            'status': interview.status.name,
            'summary': interview.summary,
            'recommendation': interview.recommendation?.name,
            'communication_score': interview.communicationScore,
            'confidence_score': interview.confidenceScore,
            'relevance_score': interview.relevanceScore,
            'completed_at': interview.completedAt?.toIso8601String(),
          })
          .select()
          .single();
      return AiInterview.fromMap(Map<String, dynamic>.from(response));
    });
  }

  static Future<void> updateAiInterview(AiInterview interview) {
    return _run(() {
      return client.from('ai_interviews').update({
        'questions': interview.questions,
        'responses': interview.responses.map((item) => item.toMap()).toList(),
        'status': interview.status.name,
        'summary': interview.summary,
        'recommendation': interview.recommendation?.name,
        'communication_score': interview.communicationScore,
        'confidence_score': interview.confidenceScore,
        'relevance_score': interview.relevanceScore,
        'completed_at': interview.completedAt?.toIso8601String(),
      }).eq('id', interview.id);
    });
  }

  static Future<String> uploadBinaryFile({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    required String contentType,
  }) {
    return _run(() async {
      final bucket = AppConfig.instance.storageBucket;
      final objectPath =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from(bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );
      return client.storage.from(bucket).getPublicUrl(objectPath);
    });
  }

  static Future<void> deleteProfile(String profileId) {
    return _run(() => client.from('profiles').delete().eq('id', profileId));
  }

  static Future<void> upsertProfileRow(Map<String, dynamic> data) {
    return _run(() => client.from('profiles').upsert(data));
  }

  static Future<void> upsertApplicationRow(Map<String, dynamic> data) {
    return _run(() => client.from('applications').upsert(data));
  }

  static Future<void> upsertMissionRow(Map<String, dynamic> data) {
    return _run(() => client.from('missions').upsert(data));
  }

  static Future<void> deleteApplication(String applicationId) {
    return _run(
      () => client.from('applications').delete().eq('id', applicationId),
    );
  }

  static Future<void> requestDeletionOtp() {
    return _run(() async {
      final response = await client.functions.invoke(
        'account-deletion',
        body: {'action': 'request-otp'},
      );
      if (response.status != 200) {
        throw XpServiceException(
          response.data['error'] ?? 'Failed to send OTP.',
        );
      }
    });
  }

  static Future<void> confirmAccountDeletion(String otp) {
    return _run(() async {
      final response = await client.functions.invoke(
        'account-deletion',
        body: {'action': 'confirm-deletion', 'otp': otp},
      );
      if (response.status != 200) {
        throw XpServiceException(
          response.data['error'] ?? 'Invalid or expired OTP.',
        );
      }
    });
  }
}
