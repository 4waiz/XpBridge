# XPBridge

XPBridge is a Flutter MVP that connects students with startup missions. Students build a reviewable profile with a CV, portfolio, and GitHub link. Startups create real missions, review applicants, request AI interviews, and leave mentor feedback. The app is wired for Supabase auth, profile storage, mission/application data, and public asset hosting.

## Stack
- Flutter
- Supabase Auth, Database, Storage, Realtime
- Gemini API for optional AI-assisted flows

## Required environment variables
Copy `.env.example` to `.env` and set:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STORAGE_BUCKET`
- `ADMIN_EMAILS`
- `GEMINI_API_KEY` if AI chat is enabled
- `SENTRY_DSN` optional
- `ANALYTICS_KEY` optional

The app fails fast on missing required keys during startup.

## Supabase setup
1. Run [`supabase/schema.sql`](/c:/Users/awaiz/OneDrive/Desktop/Git/XpBridge/xpbridge/supabase/schema.sql) in your Supabase SQL editor.
2. Create a public storage bucket matching `STORAGE_BUCKET`.
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
- Replace the placeholder Android application id and signing config as needed
- Configure a real release keystore
- Provide Play Console assets and privacy policy
- Validate reviewer accounts and admin access

See [`docs/play_console_checklist.md`](/c:/Users/awaiz/OneDrive/Desktop/Git/XpBridge/xpbridge/docs/play_console_checklist.md) for the internal/closed testing checklist.
