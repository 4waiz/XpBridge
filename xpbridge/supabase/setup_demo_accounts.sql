-- 1. CLEAN UP EXISTING DATA
-- This removes old records to keep the database focused on your 3 demo accounts.
DELETE FROM applications;
DELETE FROM missions;
DELETE FROM profiles;

-- 2. PREPARE THE PROFILES
-- NOTE: Please make sure you have created these 3 accounts in the 
-- "Authentication -> Users" tab in the Supabase Dashboard first!

-- Student Account
INSERT INTO profiles (id, name, email, role, bio, education, skills, availability_hours)
SELECT id, 'Student Demo', 'review.student@gmail.com', 'student', 
'Passionate mobile developer specializing in Flutter and Supabase logic.', 
'Computer Science @ Tech University', 
'{"Flutter", "Dart", "Supabase", "UI/UX"}', 15
FROM auth.users WHERE email = 'review.student@gmail.com'
ON CONFLICT (id) DO NOTHING;

-- Startup Account
INSERT INTO profiles (id, name, email, role, company_name, industry, bio)
SELECT id, 'Startup Admin', 'review.startup@gmail.com', 'startup', 
'XPBridge Ventures', 'EdTech',
'A forward-thinking startup building the bridge between learners and real-world experience.'
FROM auth.users WHERE email = 'review.startup@gmail.com'
ON CONFLICT (id) DO NOTHING;

-- Admin Account (Platform Manager)
INSERT INTO profiles (id, name, email, role, bio)
SELECT id, 'Admin Demo', 'review.admin@gmail.com', 'student', 
'Platform Administrator - Monitoring database performance and community growth.'
FROM auth.users WHERE email = 'review.admin@gmail.com'
ON CONFLICT (id) DO NOTHING;

-- 3. ADD SOME SEED DATA FOR DEMO
-- This ensures the "Startup" account has at least one live mission for the "Student" to apply for.

INSERT INTO missions (startup_id, title, description, commitment, estimated_hours, required_skills)
SELECT id, 'Mobile Platform Redesign', 'Help us build a premium glassy UI for our student discovery engine.', 
'10 hrs/week', 40, '{"Flutter", "UI Design"}'
FROM auth.users WHERE email = 'review.startup@gmail.com'
ON CONFLICT DO NOTHING;
