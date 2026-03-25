-- =============================================
-- XPBridge: Comprehensive Fix for Profiles Table Schema
-- This script ensures all columns required by the Student and Startup 
-- logic exist in your public.profiles table.
--
-- Run this in Supabase Dashboard → SQL Editor → New Query → Run
-- =============================================

-- Ensure essential columns exist (Basic Info)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS company_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Student Specific Columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS education TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS availability_hours NUMERIC DEFAULT 10;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS portfolio_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS github_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_file_name TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS resume_mime_type TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Gamification & Progress
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS xp_points INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS missions_completed_count INTEGER DEFAULT 0;

-- Startup Specific Columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS website_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS industry TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS required_skills TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS project_details TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Maintenance columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Refresh the PostgREST schema cache to ensure the API recognizes the new columns
NOTIFY pgrst, 'reload schema';
