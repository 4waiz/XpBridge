import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'web_url.dart';
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

/// Which auth provider the current user signed up with. Determined from
/// `User.identities` + `User.appMetadata['providers']` (Supabase's own
/// authoritative source of truth) — no guessing.
enum AuthProviderKind {
  /// Classic email + password account.
  emailPassword,

  /// Signed in via Google OAuth only.
  google,

  /// Has both password and Google linked on the same user record.
  linked,

  /// Logged-in user, but we couldn't determine a provider (shouldn't happen
  /// in practice). We treat this like `emailPassword` in the delete UI so
  /// the user at least has a path forward.
  unknown,
}

class SupabaseService {
  static final client = Supabase.instance.client;
  static const _pendingOAuthRoleKey = 'pending_oauth_role';
  static const _pendingDeleteKey = 'pending_account_delete';
  static const _deletionSuccessKey = 'account_deletion_success_message';

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

  /// The GitHub Pages project-site host and its repo sub-path. Hard-coded
  /// here because it's a deploy-time constant: Supabase needs this exact
  /// URL to be whitelisted in the dashboard Redirect URLs list, and this
  /// file is the single source of truth for what we send as `redirectTo`.
  static const String _githubPagesHost = '4waiz.github.io';
  static const String _githubPagesBasePath = '/XpBridge/';

  /// Returns the exact URL Google OAuth should bounce back to on web.
  ///
  /// Built from the live browser URL using the canonical formula
  /// `${Uri.base.origin}${Uri.base.path}` — whatever host + repo subpath
  /// Flutter was deployed at is preserved, so this works for
  /// `https://4waiz.github.io/XpBridge/` in prod and
  /// `http://localhost:<port>/` locally without any config.
  ///
  /// We additionally FORCE `/XpBridge/` on the GitHub Pages host so that
  /// even if `Uri.base.path` is ever empty or `/` (e.g. a build served
  /// without `--base-href`, a stale service worker, or a redirect that
  /// landed us on the apex before the `<base>` was parsed), we still send
  /// Supabase the real app URL instead of the domain root.
  static String webOAuthRedirectUrl() {
    final base = Uri.base;
    final origin = base.origin;
    var path = base.path;
    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    // GitHub Pages safety net.
    if (base.host == _githubPagesHost &&
        !path.startsWith(_githubPagesBasePath)) {
      path = _githubPagesBasePath;
    }

    return '$origin$path';
  }

  /// Inspects the browser URL at cold start and returns it if it carries an
  /// OAuth callback (`?code=`, `#access_token=`, or an `error_description=`).
  /// Call this BEFORE `Supabase.initialize()` — supabase_flutter's built-in
  /// `detectSessionInUri` listener can strip query params from `Uri.base`
  /// during initialization (via `window.history.replaceState`), so by the
  /// time initialize's future resolves there may be nothing left to exchange.
  static Uri? capturePendingOAuthCallback() {
    if (!kIsWeb) return null;
    try {
      final uri = Uri.base;
      final query = uri.queryParameters;
      final hasQuery = query.containsKey('code') ||
          query.containsKey('error') ||
          query.containsKey('error_description');
      final fragment = uri.fragment;
      final hasFragment = fragment.contains('access_token=') ||
          fragment.contains('code=') ||
          fragment.contains('error=') ||
          fragment.contains('error_description=');
      if (hasQuery || hasFragment) {
        debugPrint('[oauth] callback detected @ $uri');
        return uri;
      }
    } catch (error, stack) {
      debugPrint('[oauth] capture failed: $error\n$stack');
    }
    return null;
  }

  /// Finishes a web OAuth callback. Exchanges the code for a Supabase session
  /// using the URL captured at cold start. The browser URL is always cleaned
  /// afterwards (success or failure) so GoRouter never sees a stale `?code=`
  /// and pins the user to the splash.
  ///
  /// Safe to call at boot — returns quickly if the captured URL is null, if
  /// we're not on web, or if supabase_flutter's built-in auto-detect already
  /// restored a session. Swallows failures so boot never hangs; the app will
  /// fall through to `/login` if the exchange genuinely failed.
  static Future<void> ensureSessionFromPendingCallback(Uri? callbackUri) async {
    if (!kIsWeb || callbackUri == null) return;

    try {
      if (client.auth.currentSession != null) {
        debugPrint('[oauth] session already present — skipping manual exchange');
        return;
      }

      debugPrint('[oauth] code exchange started');
      // getSessionFromUrl handles both PKCE (?code=) and implicit
      // (#access_token=) flows, persists the session, and notifies listeners.
      final response = await client.auth
          .getSessionFromUrl(callbackUri)
          .timeout(const Duration(seconds: 15));
      debugPrint(
        '[oauth] code exchange success (user=${response.session.user.id})',
      );
    } catch (error, stack) {
      debugPrint('[oauth] code exchange failure: $error\n$stack');
    } finally {
      // Always strip any ?code=/#access_token= from the URL so GoRouter's
      // redirect logic — and any user who reloads — sees a clean state.
      // We keep the GitHub Pages base path and land on /#/login which the
      // router will then resolve to the real post-auth destination based
      // on the current session.
      _cleanCallbackUrl();
    }
  }

  static void _cleanCallbackUrl() {
    if (!kIsWeb) return;
    try {
      final base = Uri.base;
      var path = base.path;
      if (path.isEmpty) path = '/';
      if (!path.endsWith('/')) path = '$path/';
      // Force the GitHub Pages project sub-path if we're on that host so we
      // never end up with a bare-domain URL after cleanup.
      if (base.host == _githubPagesHost && !path.startsWith(_githubPagesBasePath)) {
        path = _githubPagesBasePath;
      }
      final cleaned = '${base.origin}$path#/login';
      replaceBrowserUrl(cleaned);
      debugPrint('[oauth] url cleaned -> $cleaned');
    } catch (error, stack) {
      debugPrint('[oauth] url clean failed: $error\n$stack');
    }
  }

  /// Signals that the user cancelled the native Google Sign-In sheet. UI
  /// layers catch this specifically so they can silently reset their loading
  /// state without showing an "error" snackbar.
  static const XpServiceException googleSignInCancelled =
      XpServiceException('Google sign-in was cancelled.');

  /// Signs the user in with Google.
  ///
  /// Behaviour depends on the platform:
  ///
  /// * **Web** → keeps the existing Supabase PKCE/browser OAuth flow.
  ///   Hash/query callback handling is wired through
  ///   [capturePendingOAuthCallback] / [ensureSessionFromPendingCallback]
  ///   in `main.dart`, so nothing else needs to change here.
  /// * **Android** → uses the native Google Sign-In sheet via the
  ///   `google_sign_in` plugin. No Chrome Custom Tab, no browser bounce.
  ///   The resulting id_token is exchanged with Supabase through
  ///   `auth.signInWithIdToken`, producing a normal Supabase session.
  /// * **iOS** → currently falls back to the browser OAuth flow. Native
  ///   Google Sign-In on iOS requires the GIDClientID in Info.plist and a
  ///   reversed-client URL scheme — see the TODO below before flipping the
  ///   switch for iOS.
  ///
  /// The `role` parameter (used only on first-time signups) is persisted
  /// locally via [SharedPreferences] so [ensureProfileForCurrentUser] can
  /// pick it up after the session is established — regardless of which
  /// platform branch ran.
  static Future<void> signInWithGoogle({String? role}) {
    return _run(() async {
      final prefs = await SharedPreferences.getInstance();
      if (role == null) {
        await prefs.remove(_pendingOAuthRoleKey);
      } else {
        await prefs.setString(_pendingOAuthRoleKey, role);
      }

      if (kIsWeb) {
        await _signInWithGoogleWeb();
        return;
      }

      if (_isAndroid) {
        await _signInWithGoogleNative();
        return;
      }

      // iOS / desktop → keep the browser-based flow until native is wired up.
      // TODO(ios-native-google): to enable native Google Sign-In on iOS:
      //   1. Add `GOOGLE_IOS_CLIENT_ID` to `.env` (iOS OAuth client from
      //      Google Cloud Console).
      //   2. Add reversed-client URL scheme to `ios/Runner/Info.plist` under
      //      `CFBundleURLTypes` (format:
      //      `com.googleusercontent.apps.<client-id-prefix>`).
      //   3. Set `GIDClientID` in Info.plist to the iOS client ID.
      //   4. Replace this branch with a call to [_signInWithGoogleNative].
      await _signInWithGoogleWeb();
    });
  }

  static bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _signInWithGoogleWeb() async {
    final String redirectTo = kIsWeb
        ? webOAuthRedirectUrl()
        : 'io.supabase.xpbridge://login-callback';

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
  }

  /// Native Google Sign-In (Android today, iOS once configured).
  ///
  /// Flow:
  ///   1. Prompt the OS-level Google account picker via `google_sign_in`.
  ///   2. Read the id_token + access_token from the returned auth object.
  ///   3. Exchange them for a Supabase session via `signInWithIdToken`.
  ///
  /// The `serverClientId` we pass to `GoogleSignIn` MUST be the **Web**
  /// OAuth client ID registered in Supabase (not the Android one). Supabase
  /// validates the `aud` claim on the id_token against the web client, so
  /// if we pass the Android client ID here Supabase rejects the exchange
  /// with "Unacceptable audience in id_token". The Android OAuth client
  /// still matters — Google uses package name + SHA-1 to decide whether
  /// to sign the token at all — but it is not referenced by client code.
  static Future<void> _signInWithGoogleNative() async {
    final webClientId = AppConfig.instance.googleWebClientId;
    if (webClientId == null || webClientId.isEmpty) {
      throw const XpServiceException(
        'Google sign-in is not configured for this build '
        '(missing GOOGLE_WEB_CLIENT_ID).',
      );
    }

    final iosClientId = AppConfig.instance.googleIosClientId;

    final googleSignIn = GoogleSignIn(
      // On Android: `serverClientId` triggers Google to mint an id_token
      // whose audience is the web client — exactly what Supabase wants.
      serverClientId: webClientId,
      // On iOS (once wired up) we need to pass the iOS client ID here.
      // On Android this is ignored.
      clientId: iosClientId,
      scopes: const ['email', 'profile', 'openid'],
    );

    // Make sure any previous session on the device doesn't short-circuit
    // the account picker — we want the user to see the Google sheet every
    // time they explicitly tap "Continue with Google".
    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Non-fatal: a fresh install / first run has nothing to sign out of.
    }

    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (error) {
      throw XpServiceException(_nativeGoogleErrorMessage(error));
    }

    if (account == null) {
      // User dismissed the Google sheet. Propagate a sentinel so the UI
      // resets cleanly without flashing a scary error.
      throw googleSignInCancelled;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw const XpServiceException(
        'Google did not return an ID token. Check that the Android OAuth '
        'client is registered with the correct SHA-1 and package name.',
      );
    }

    try {
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (error) {
      throw XpServiceException(
        'Supabase rejected the Google session: ${error.message}',
      );
    }
  }

  static String _nativeGoogleErrorMessage(PlatformException error) {
    final code = error.code;
    if (code == 'network_error') {
      return 'Network error signing in with Google. Check your connection '
          'and try again.';
    }
    if (code == 'sign_in_failed' || code == '10') {
      // DEVELOPER_ERROR = 10: usually a missing/incorrect SHA-1 in the
      // Google Cloud Android OAuth client, or the wrong package name.
      return 'Google sign-in is not set up correctly for this build '
          '(code=$code). Verify the Android OAuth client SHA-1 + package '
          'name in Google Cloud Console.';
    }
    final detail = error.message?.trim();
    if (detail == null || detail.isEmpty) {
      return 'Google sign-in failed (code=$code).';
    }
    return 'Google sign-in failed: $detail';
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
    if (user == null) {
      debugPrint('[oauth] ensureProfile: no current user');
      return null;
    }

    debugPrint('[oauth] profile fetch started (user=${user.id})');
    try {
      final existingProfile = await getCurrentProfileRecord();
      if (existingProfile != null) {
        debugPrint(
          '[oauth] profile fetch success: existing row (role=${existingProfile['role']})',
        );
        await _clearPendingOAuthRole();
        return existingProfile;
      }
    } catch (error, stack) {
      // Never hang the splash on a profile read failure — bubble it up as a
      // typed service error so `refreshSession` can surface it and release
      // the bootstrap gate.
      debugPrint('[oauth] profile fetch failure: $error\n$stack');
      if (error is XpServiceException) rethrow;
      throw XpServiceException('Could not load your profile ($error).');
    }

    debugPrint('[oauth] profile fetch success: no existing row');
    final prefs = await SharedPreferences.getInstance();
    final pendingRole = prefs.getString(_pendingOAuthRoleKey);
    if (pendingRole != 'student' && pendingRole != 'startup') {
      debugPrint(
        '[oauth] no pending role — routing user to /signup for role picker',
      );
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
      'name': displayName,
      'company_name': pendingRole == 'startup' ? displayName : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    debugPrint(
      '[oauth] creating profile row for Google user (role=$pendingRole)',
    );
    try {
      await client.from('profiles').upsert(profile);
    } on PostgrestException catch (error) {
      throw XpServiceException(
        'Could not create your profile (${error.message}).',
      );
    } catch (error) {
      throw XpServiceException('Could not create your profile ($error).');
    }
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

  // ---------------------------------------------------------------------------
  // Account deletion
  // ---------------------------------------------------------------------------

  /// Returns the auth provider the current user signed in with. Derived from
  /// `User.identities` (authoritative) with a fallback to
  /// `appMetadata['providers']` / `appMetadata['provider']`.
  static AuthProviderKind currentAuthProvider() {
    final user = currentUser;
    if (user == null) return AuthProviderKind.unknown;

    final providers = <String>{};

    for (final identity in user.identities ?? const <UserIdentity>[]) {
      providers.add(identity.provider.toLowerCase());
    }

    final metaList = user.appMetadata['providers'];
    if (metaList is List) {
      for (final entry in metaList) {
        providers.add(entry.toString().toLowerCase());
      }
    }
    final metaSingle = user.appMetadata['provider'];
    if (metaSingle is String && metaSingle.isNotEmpty) {
      providers.add(metaSingle.toLowerCase());
    }

    final hasGoogle = providers.contains('google');
    final hasEmail = providers.contains('email');

    if (hasGoogle && hasEmail) return AuthProviderKind.linked;
    if (hasGoogle) return AuthProviderKind.google;
    if (hasEmail) return AuthProviderKind.emailPassword;
    return AuthProviderKind.unknown;
  }

  /// Email/password deletion path: verify the password locally by
  /// re-authenticating, then call the server to purge data + auth user.
  static Future<void> deleteAccountWithPassword(String password) {
    return _run(() async {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw const XpServiceException(
          'Your session has expired. Log in again, then retry account deletion.',
        );
      }

      try {
        await client.auth.signInWithPassword(
          email: user.email!,
          password: password,
        );
      } on AuthException {
        throw const XpServiceException('Incorrect password.');
      }

      await _invokeAccountDeletionEdgeFunction();
      await _signOutQuietly();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _deletionSuccessKey,
        'Your account has been deleted.',
      );
    });
  }

  /// Google-reauth deletion path (phase 1 — kicks off). Stores a "pending
  /// delete" flag in local storage and launches the normal Google OAuth
  /// flow. When the browser / Chrome Custom Tab returns to the app,
  /// `executePendingAccountDeletion()` (called from main.dart during
  /// bootstrap) picks up the flag and actually deletes the account while
  /// the JWT is freshly-minted.
  ///
  /// Throws `XpServiceException` if we can't even launch the OAuth flow;
  /// otherwise control transfers to the browser and the future completes
  /// once the browser tab has been opened.
  static Future<void> beginGoogleReauthForAccountDeletion() async {
    if (currentUser == null) {
      throw const XpServiceException(
        'Your session has expired. Log in again, then retry account deletion.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingDeleteKey, true);
    await prefs.remove(_deletionSuccessKey);

    try {
      await signInWithGoogle();
    } catch (error) {
      // Failed to even open the browser — don't leave a sticky flag behind.
      await prefs.remove(_pendingDeleteKey);
      rethrow;
    }
  }

  /// Called at app bootstrap (from `main.dart`) AFTER the session has been
  /// restored. If the user previously triggered a Google-reauth delete and
  /// came back signed in, we finish the job here: call the edge function,
  /// sign out, and drop a success message the login screen can pick up.
  ///
  /// Returns `true` if a deletion was executed (in which case the caller
  /// should expect `currentUser` to be null). Returns `false` if there was
  /// nothing pending or if we no longer have a valid session to act on.
  static Future<bool> executePendingAccountDeletion() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingDeleteKey) ?? false;
    if (!pending) return false;

    // No session → the reauth never completed. Clear the flag so we don't
    // loop the next time the user opens the app.
    if (currentUser == null) {
      await prefs.remove(_pendingDeleteKey);
      debugPrint('[delete] pending flag present but no session — clearing');
      return false;
    }

    debugPrint('[delete] executing pending Google-reauth deletion');
    try {
      await _invokeAccountDeletionEdgeFunction();
      await _signOutQuietly();
      await prefs.setString(
        _deletionSuccessKey,
        'Your account has been deleted.',
      );
      debugPrint('[delete] pending deletion complete');
      return true;
    } on XpServiceException catch (error) {
      debugPrint('[delete] pending deletion failed: ${error.message}');
      await prefs.setString(
        _deletionSuccessKey,
        'Account deletion failed: ${error.message}',
      );
      return false;
    } catch (error, stack) {
      debugPrint('[delete] pending deletion threw: $error\n$stack');
      await prefs.setString(
        _deletionSuccessKey,
        'Account deletion failed. Please try again.',
      );
      return false;
    } finally {
      // Clear the trigger either way — the user can retry from the UI.
      await prefs.remove(_pendingDeleteKey);
    }
  }

  /// Reads (and clears) any one-shot message left behind by a completed
  /// deletion. The login screen calls this on mount and surfaces the text
  /// as a snackbar.
  static Future<String?> consumeDeletionStatusMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final message = prefs.getString(_deletionSuccessKey);
    if (message != null) {
      await prefs.remove(_deletionSuccessKey);
    }
    return message;
  }

  static Future<void> _invokeAccountDeletionEdgeFunction() async {
    final response = await client.functions.invoke(
      'account-deletion',
      body: {'action': 'delete'},
    );

    if (response.status == 200) return;

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

  static Future<void> _signOutQuietly() async {
    try {
      await client.auth.signOut();
    } catch (_) {
      // The auth user is already deleted server-side; local sign-out is
      // best-effort and can fail with "user not found".
    }
  }
}
