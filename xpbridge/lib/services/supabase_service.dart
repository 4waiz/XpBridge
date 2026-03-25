import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import '../models/startup_profile.dart';
import '../models/startup_role.dart';
import '../models/application.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // --- Auth ---
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Profiles ---
  static Future<StudentProfile?> getStudentProfile(String id) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .eq('role', 'student')
          .single();
      return StudentProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  static Future<StartupProfile?> getStartupProfile(String id) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .eq('role', 'startup')
          .single();
      return StartupProfile.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // --- Profile Updates ---
  static Future<void> updateProfile({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await client.from('profiles').update(data).eq('id', id);
  }

  // =============================================
  // MISSIONS — Real-time & CRUD
  // =============================================

  /// Real-time stream of all open missions.
  /// Every INSERT / UPDATE / DELETE on the `missions` table triggers a new
  /// snapshot, so every student's dashboard refreshes instantly.
  static Stream<List<Map<String, dynamic>>> missionsStream() {
    return client
        .from('missions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// One-shot fetch — used as a fallback or initial load.
  static Future<List<Map<String, dynamic>>> getMissions() async {
    final response = await client
        .from('missions')
        .select('*, profiles(company_name, profile_image_url)')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Push a new mission to Supabase when a startup creates a role.
  static Future<void> createMissionFromRole({
    required String startupId,
    required StartupRole role,
    List<String> requiredSkills = const [],
  }) async {
    await client.from('missions').insert({
      'startup_id': startupId,
      'title': role.title,
      'description': role.description ?? role.learningOutcome,
      'commitment': role.commitment,
      'estimated_hours': role.estimatedHours,
      'learning_outcome': role.learningOutcome,
      'required_skills': requiredSkills,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Legacy helper kept for backward compatibility.
  static Future<void> createMission(Map<String, dynamic> data) async {
    await client.from('missions').insert(data);
  }

  // =============================================
  // APPLICATIONS — Real-time & CRUD
  // =============================================

  /// Push a new application to Supabase (student applies to a role).
  static Future<void> submitApplication(Application app) async {
    await client.from('applications').insert(app.toSupabaseMap());
  }

  /// Real-time stream of applications for a specific startup.
  /// The startup dashboard listens to this to see new apps arrive.
  static Stream<List<Map<String, dynamic>>> applicationsStreamForStartup(
    String startupId,
  ) {
    return client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('startup_id', startupId)
        .order('applied_at', ascending: false);
  }

  /// Real-time stream of applications for a specific student.
  static Stream<List<Map<String, dynamic>>> applicationsStreamForStudent(
    String studentId,
  ) {
    return client
        .from('applications')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('applied_at', ascending: false);
  }

  /// One-shot fetch of all applications for a startup.
  static Future<List<Map<String, dynamic>>> getApplicationsForStartup(
    String startupId,
  ) async {
    final response = await client
        .from('applications')
        .select()
        .eq('startup_id', startupId)
        .order('applied_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update application status (startup accepts/rejects/completes).
  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    await client.from('applications').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);
  }

  /// Update application with reflection data (student submits reflection).
  static Future<void> updateApplicationReflection(
    String applicationId,
    Map<String, dynamic> reflectionData,
  ) async {
    await client
        .from('applications')
        .update({
          ...reflectionData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  }

  /// Update application with mentor feedback (startup leaves feedback).
  static Future<void> updateApplicationFeedback(
    String applicationId,
    Map<String, dynamic> feedbackData,
  ) async {
    await client
        .from('applications')
        .update({
          ...feedbackData,
          'feedback_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  }

  /// Legacy helper kept for backward compatibility.
  static Future<void> applyToMission({
    required String studentId,
    required String missionId,
    String? message,
  }) async {
    await client.from('applications').insert({
      'student_id': studentId,
      'mission_id': missionId,
      'message': message,
      'status': 'pending',
      'applied_at': DateTime.now().toIso8601String(),
    });
  }
}
