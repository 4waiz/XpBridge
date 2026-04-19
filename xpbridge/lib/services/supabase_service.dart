import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
    } on FunctionException catch (error) {
      final details = error.details?.toString() ?? '';
      final reason = error.reasonPhrase?.toString() ?? '';
      final fallbackMessage = error.toString();
      final combined = '$fallbackMessage $details $reason'.toLowerCase();
      if (combined.contains('invalid jwt') ||
          combined.contains('unauthorized') ||
          combined.contains('401')) {
        throw const XpServiceException(
          'Your session has expired. Log in again, then retry account deletion.',
        );
      }
      throw XpServiceException(fallbackMessage);
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

      // If Supabase has email confirmation enabled, the user won't have a
      // session yet. In that case, auto-sign-in so the closed-testing flow
      // works seamlessly on real devices (no broken confirmation links).
      final authenticatedUser = client.auth.currentUser;
      if (authenticatedUser == null || authenticatedUser.id != response.user!.id) {
        // Try signing in immediately (works when confirm-email is OFF or
        // autoconfirm is ON in Supabase dashboard).
        try {
          await client.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } on AuthException {
          // Email confirmation is truly required; tell the user clearly.
          throw const XpServiceException(
            'Account created! Check your inbox for a confirmation link, then come back and log in.',
          );
        }
      }

      final userId = client.auth.currentUser!.id;
      await client.from('profiles').upsert({
        'id': userId,
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
    final String redirectTo = kIsWeb
        ? Uri.base.origin
        : 'io.supabase.xpbridge://login-callback';

    return _run(() async {
      final prefs = await SharedPreferences.getInstance();
      if (role == null) {
        await prefs.remove(_pendingOAuthRoleKey);
      } else {
        await prefs.setString(_pendingOAuthRoleKey, role);
      }

      // Force the system browser (Chrome Custom Tabs on Android) so the
      // PKCE callback deep-links back into the app reliably. Google blocks
      // OAuth inside embedded WebViews, so relying on platformDefault has
      // been known to silently fail on some devices.
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const XpServiceException(
          'Could not open Google sign-in. Make sure you have a browser '
          'installed and try again.',
        );
      }
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
        'profile_image_url': profile.profileImageUrl,
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

  static Future<List<AiInterview>> getAllAiInterviews() async {
    return _run(() async {
      final response = await client
          .from('ai_interviews')
          .select()
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
      final config = AppConfig.instance;
      final bucket = config.storageBucket;
      final safeName = _sanitizeFileName(fileName);
      final objectPath =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      if (kIsWeb) {
        final session = client.auth.currentSession;
        final accessToken = session?.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          throw const XpServiceException(
            'Your session is missing. Log in again, then retry the upload.',
          );
        }

        final encodedObjectPath = objectPath
            .split('/')
            .map(Uri.encodeComponent)
            .join('/');
        final uploadUri = Uri.parse(
          '${config.supabaseUrl}/storage/v1/object/$bucket/$encodedObjectPath',
        );

        final response = await http.post(
          uploadUri,
          headers: {
            'apikey': config.supabaseAnonKey,
            'Authorization': 'Bearer $accessToken',
            'Content-Type': contentType,
            'x-upsert': 'false',
          },
          body: bytes,
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw XpServiceException(
            _storageErrorMessage(response.statusCode, response.body),
          );
        }
      } else {
        await client.storage.from(bucket).uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );
      }

      final encodedPublicPath =
          objectPath.split('/').map(Uri.encodeComponent).join('/');
      return '${config.supabaseUrl}/storage/v1/object/public/$bucket/$encodedPublicPath';
    });
  }

  /// Removes a file previously uploaded via [uploadBinaryFile]. Accepts either
  /// a storage object path (e.g. `resumes/<uid>/<file>`) or the full public URL
  /// returned by the upload. Swallows failures so callers can replace stale
  /// files opportunistically without breaking the main flow.
  static Future<void> tryDeleteStorageObject(String? pathOrUrl) async {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return;
    final config = AppConfig.instance;
    final bucket = config.storageBucket;
    final marker = '/object/public/$bucket/';
    String objectPath = pathOrUrl.trim();
    final idx = objectPath.indexOf(marker);
    if (idx >= 0) {
      objectPath = objectPath.substring(idx + marker.length);
    }
    try {
      objectPath = Uri.decodeFull(objectPath);
    } catch (_) {}
    if (objectPath.isEmpty || objectPath.contains('://')) return;
    try {
      await client.storage.from(bucket).remove([objectPath]);
    } catch (_) {
      // Non-fatal: orphan cleanup shouldn't fail the primary replace flow.
    }
  }

  static String _sanitizeFileName(String name) {
    final trimmed = name.trim().isEmpty ? 'upload' : name.trim();
    // Keep letters, digits, dots, dashes, underscores; replace the rest.
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  }

  static String _storageErrorMessage(int statusCode, String body) {
    final trimmed = body.trim();
    String detail = '';
    if (trimmed.isNotEmpty) {
      try {
        final parsed = jsonDecode(trimmed);
        if (parsed is Map<String, dynamic>) {
          detail = parsed['message']?.toString() ??
              parsed['error']?.toString() ??
              trimmed;
        } else {
          detail = trimmed;
        }
      } catch (_) {
        detail = trimmed;
      }
    }
    final lower = detail.toLowerCase();
    if (statusCode == 401 || statusCode == 403 ||
        lower.contains('row-level security') ||
        lower.contains('permission denied') ||
        lower.contains('violates row') ||
        lower.contains('not authorized')) {
      return 'Upload blocked by storage permissions. Please log out, log in '
          'again, and retry. If the issue persists, contact support.';
    }
    if (detail.isEmpty) {
      return 'Upload failed (status $statusCode). Please try again.';
    }
    return 'Upload failed: $detail';
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

  static Future<void> upsertAiInterviewRow(Map<String, dynamic> data) {
    return _run(() => client.from('ai_interviews').upsert(data));
  }

  static Future<void> deleteApplication(String applicationId) {
    return _run(
      () => client.from('applications').delete().eq('id', applicationId),
    );
  }

  static Future<void> deleteAiInterview(String interviewId) {
    return _run(() => client.from('ai_interviews').delete().eq('id', interviewId));
  }

  /// Verifies the user's password by re-authenticating, then calls the
  /// server-side Edge Function to purge data and delete the auth user.
  static Future<void> deleteAccountWithPassword(String password) {
    return _run(() async {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw const XpServiceException(
          'Your session has expired. Log in again, then retry account deletion.',
        );
      }

      // Step 1: Verify password by re-authenticating
      try {
        await client.auth.signInWithPassword(
          email: user.email!,
          password: password,
        );
      } on AuthException {
        throw const XpServiceException('Incorrect password.');
      }

      // Step 2: Call Edge Function to delete server-side
      final response = await client.functions.invoke(
        'account-deletion',
        body: {'action': 'delete'},
      );
      if (response.status != 200) {
        final errorData = response.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['error'] as String?
            : null;
        if (response.status == 401 || errorMessage == 'Unauthorized') {
          throw const XpServiceException(
            'Your session has expired. Log in again, then retry account deletion.',
          );
        }
        throw XpServiceException(
          errorMessage ?? 'Account deletion failed. Please try again.',
        );
      }

      // Step 3: Sign out locally
      try {
        await client.auth.signOut();
      } catch (_) {
        // Auth user is already deleted server-side; local sign-out may fail.
      }
    });
  }
}
