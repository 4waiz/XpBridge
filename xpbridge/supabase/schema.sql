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

-- 3. Applications Table
CREATE TABLE applications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE NOT NULL,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'interviewing', 'accepted', 'rejected', 'completed', 'hired')),
  message TEXT,
  deliverable_url TEXT,
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
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
