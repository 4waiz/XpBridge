# XPBridge Play Console Checklist

## Required assets
- 512x512 app icon
- Feature graphic
- Phone screenshots for student flow and startup flow
- Privacy policy URL

## Required declarations
- Category: Education / Business depending on positioning
- Account creation required: Yes
- App access instructions required: Yes
- Data safety form required: Yes
- Content rating questionnaire required: Yes
- Release must be signed with the upload keystore configured through `android/key.properties`
- Release must not use the Android debug signing key

## App access notes
- Reviewers need a student test account and a startup test account
- If admin review is needed, mark one existing profile as `is_admin = true`
- Reviewer paths:
  - Student: sign up, complete profile, upload CV, browse missions, apply
  - Startup: sign up, complete company profile, create mission, review applicants, leave feedback

## Data collected
- Email address
- Profile details
- CV file URL and metadata
- Portfolio / GitHub / website links
- Mission and application data
- Mentor feedback and AI interview results

## Permissions used
- Internet access only
- No camera, contacts, location, or sensitive media permissions requested

## Tester flow
- Student:
  - Create account
  - Complete setup with CV upload
  - Browse missions
  - Apply to a mission
  - Open applications screen and complete AI interview if requested
- Startup:
  - Create account
  - Complete company setup
  - Add a mission
  - Review student profile, CV, GitHub, and portfolio
  - Accept application and leave feedback

## Reviewer credential strategy
- Keep one seeded student auth account and one startup auth account in Supabase Auth
- Optional admin account:
  - Same flow as above, but set `profiles.is_admin = true`
- Never ship credentials in the repo or APK
- Never ship service-role keys, Resend keys, Gemini server keys, or keystore passwords in the Flutter client bundle
