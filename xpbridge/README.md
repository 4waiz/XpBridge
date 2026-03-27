# XPBridge

XPBridge is a Flutter MVP that connects students with startup missions. Students build a reviewable profile with a CV, portfolio, and GitHub link. Startups create real missions, review applicants, request AI interviews, and leave mentor feedback. The app is wired for Supabase auth, profile storage, mission/application data, and public asset hosting.

## Stack
- Flutter
- Supabase Auth, Database, Storage, Realtime
- Optional AI features must be proxied through a secure backend before they are enabled in the mobile client

## Required environment variables
Copy `.env.example` to `.env` and set:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STORAGE_BUCKET`
- `ENABLE_AI_CHAT=false`

Only client-safe values belong in the bundled Flutter `.env`. Never place privileged or server-only secrets in the mobile client, including:

- `SUPABASE_SERVICE_ROLE_KEY`
- `RESEND_API_KEY`
- Gemini or other provider server API keys
- Admin allowlists, reviewer credentials, or any other privileged access controls

The app fails fast on missing required keys or unsupported bundled env keys during startup.

## Supabase setup
1. Run [`supabase/schema.sql`](/c:/Users/awaiz/OneDrive/Desktop/Git/XpBridge/xpbridge/supabase/schema.sql) in your Supabase SQL editor.
2. Run [`supabase/storage_policies.sql`](/c:/Users/omerj/Downloads/XpBridge/xpbridge/supabase/storage_policies.sql) to create the storage bucket and its upload policies.
3. Mark any admin account by setting `profiles.is_admin = true`.
4. Make sure Supabase Auth email/password sign-in is enabled.

## Local development
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Core flows
- Student:
  - Sign up
  - Complete profile with CV upload
  - Add skills, portfolio link, GitHub link, and availability
  - Browse live missions
  - Apply to a mission
  - Track status and submit reflection
- Startup:
  - Sign up
  - Complete company profile with website and required skills
  - Create missions
  - Browse student profiles
  - Open CV, portfolio, and GitHub links
  - Review applicants
  - Request AI interview
  - Leave mentor feedback
- Admin:
  - View, add, edit, and delete profiles, missions, and applications

## Release build
```bash
flutter build appbundle
```

Before release:
- Keep the bundled `.env` limited to client-safe values only
- Create an Android upload keystore and place it outside git tracking
- Copy [`android/key.properties.example`](/c:/Users/awaiz/OneDrive/Desktop/Git/XpBridge/xpbridge/android/key.properties.example) to `android/key.properties` and fill in the real keystore path, alias, and passwords
- Verify the release build is signed with the upload keystore, not the debug keystore
- Provide Play Console assets and privacy policy
- Validate reviewer accounts and admin access

See [`docs/play_console_checklist.md`](/c:/Users/awaiz/OneDrive/Desktop/Git/XpBridge/xpbridge/docs/play_console_checklist.md) for the internal/closed testing checklist.
