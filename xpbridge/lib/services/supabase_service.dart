import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import '../models/startup_profile.dart';
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
      // Create the profile entry immediately
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

  // --- Missions ---
  static Future<List<Map<String, dynamic>>> getMissions() async {
    final response = await client
        .from('missions')
        .select('*, profiles(company_name, profile_image_url)');
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Applications ---
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

  // --- Profile Updates ---
  static Future<void> updateProfile({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await client.from('profiles').update(data).eq('id', id);
  }

  static Future<void> createMission(Map<String, dynamic> data) async {
    await client.from('missions').insert(data);
  }
}
