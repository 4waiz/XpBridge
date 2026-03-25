-- Run this in Supabase SQL Editor to add the missing columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS portfolio_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS description TEXT;
