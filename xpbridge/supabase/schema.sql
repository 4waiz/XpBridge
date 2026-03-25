-- SQL Schema for XPBridge Supabase Integration
-- Run this in your Supabase SQL Editor

-- 1. Profiles Table (Unified for Students and Startups)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT CHECK (role IN ('student', 'startup')) NOT NULL,
  bio TEXT,
  profile_image_url TEXT,
  
  -- Student Specific
  education TEXT,
  skills TEXT[] DEFAULT '{}',
  availability_hours NUMERIC DEFAULT 0,
  xp_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  missions_completed_count INTEGER DEFAULT 0,
  
  -- Startup Specific
  company_name TEXT,
  website_url TEXT,
  industry TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Missions Table 
CREATE TABLE missions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  startup_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  commitment TEXT, -- e.g. '10 hrs/week'
  estimated_hours INTEGER,
  learning_outcome TEXT,
  required_skills TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Applications Table (expanded to match app model)
CREATE TABLE applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  startup_id UUID NOT NULL,
  student_name TEXT NOT NULL DEFAULT '',
  startup_name TEXT NOT NULL DEFAULT '',
  role_title TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'interviewing', 'accepted', 'rejected', 'completed', 'hired')),
  message TEXT,
  deliverable_url TEXT,
  deliverable_type TEXT,
  reflection_did TEXT,
  reflection_learned TEXT,
  skills_practiced TEXT[] DEFAULT '{}',
  hours_spent INTEGER,
  mentor_rating INTEGER,
  mentor_feedback_text TEXT,
  strengths TEXT[] DEFAULT '{}',
  growth_areas TEXT[] DEFAULT '{}',
  endorsed_skills TEXT[] DEFAULT '{}',
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  feedback_at TIMESTAMPTZ
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- 5. Public Access Policies (Example: Everyone can view open missions)
CREATE POLICY "Missions are viewable by everyone" ON missions
  FOR SELECT USING (status = 'open');

-- 6. Profile Access Policies (Users can only edit their own profile)
CREATE POLICY "Users can edit their own profiles" ON profiles
  FOR ALL USING (auth.uid() = id);

-- 7. Startups can insert their own missions
CREATE POLICY "Startups can insert own missions" ON missions
  FOR INSERT WITH CHECK (auth.uid() = startup_id);

-- 8. Startups can update/delete their own missions
CREATE POLICY "Startups can manage own missions" ON missions
  FOR UPDATE USING (auth.uid() = startup_id);

-- 9. Everyone can read all profiles (needed for company names in feeds)
CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- 10. Enable Supabase Realtime on missions table
ALTER PUBLICATION supabase_realtime ADD TABLE missions;

-- 11. Students can insert their own applications
CREATE POLICY "Students can insert own applications" ON applications
  FOR INSERT WITH CHECK (auth.uid() = student_id);

-- 12. Students can view their own applications
CREATE POLICY "Students can view own applications" ON applications
  FOR SELECT USING (auth.uid() = student_id);

-- 13. Startups can view applications for their missions
CREATE POLICY "Startups can view applications for their roles" ON applications
  FOR SELECT USING (auth.uid()::text = startup_id::text);

-- 14. Startups can update application status (accept/reject/complete)
CREATE POLICY "Startups can update applications" ON applications
  FOR UPDATE USING (auth.uid()::text = startup_id::text);

-- 15. Enable Supabase Realtime on applications table
ALTER PUBLICATION supabase_realtime ADD TABLE applications;
