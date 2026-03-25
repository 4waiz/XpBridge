-- =============================================
-- XPBridge: Migrate applications table + enable realtime
-- Run this in Supabase Dashboard → SQL Editor → New Query → Run
-- =============================================

-- 1. Add missing columns to the existing applications table
ALTER TABLE applications ADD COLUMN IF NOT EXISTS startup_id UUID;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS student_name TEXT DEFAULT '';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS startup_name TEXT DEFAULT '';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS role_title TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS deliverable_type TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS reflection_did TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS reflection_learned TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS skills_practiced TEXT[] DEFAULT '{}';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS hours_spent INTEGER;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS mentor_rating INTEGER;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS mentor_feedback_text TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS strengths TEXT[] DEFAULT '{}';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS growth_areas TEXT[] DEFAULT '{}';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS endorsed_skills TEXT[] DEFAULT '{}';
ALTER TABLE applications ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS feedback_at TIMESTAMPTZ;

-- 2. Make mission_id nullable (apps can be created without a specific mission)
ALTER TABLE applications ALTER COLUMN mission_id DROP NOT NULL;

-- 3. RLS Policies for applications
-- (Drop first in case they already exist, then re-create)
DROP POLICY IF EXISTS "Students can insert own applications" ON applications;
DROP POLICY IF EXISTS "Students can view own applications" ON applications;
DROP POLICY IF EXISTS "Startups can view applications for their roles" ON applications;
DROP POLICY IF EXISTS "Startups can update applications" ON applications;

CREATE POLICY "Students can insert own applications" ON applications
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can view own applications" ON applications
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Startups can view applications for their roles" ON applications
  FOR SELECT USING (auth.uid()::text = startup_id::text);

CREATE POLICY "Startups can update applications" ON applications
  FOR UPDATE USING (auth.uid()::text = startup_id::text);

-- 4. RLS Policies for missions (if not already set)
DROP POLICY IF EXISTS "Startups can insert own missions" ON missions;
DROP POLICY IF EXISTS "Startups can manage own missions" ON missions;

CREATE POLICY "Startups can insert own missions" ON missions
  FOR INSERT WITH CHECK (auth.uid() = startup_id);

CREATE POLICY "Startups can manage own missions" ON missions
  FOR UPDATE USING (auth.uid() = startup_id);

-- 5. Everyone can read profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;

CREATE POLICY "Profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- 6. Enable Realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE missions;
ALTER PUBLICATION supabase_realtime ADD TABLE applications;
