-- XPBridge Account Deletion System Migration
-- This script adds the necessary tables for secure account deletion and public requests.

-- 1. Table for public deletion requests (Fallback for locked-out users)
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for public.account_deletion_requests
ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert a request (Publicly accessible form)
DROP POLICY IF EXISTS "Anyone can insert deletion requests" ON public.account_deletion_requests;
CREATE POLICY "Anyone can insert deletion requests" ON public.account_deletion_requests
    FOR INSERT WITH CHECK (true);

-- Policy: Only Admins can view/manage requests
DROP POLICY IF EXISTS "Admins can view deletion requests" ON public.account_deletion_requests;
CREATE POLICY "Admins can view deletion requests" ON public.account_deletion_requests
    FOR ALL USING (public.is_admin());


-- 2. Table for secure account deletion OTPs
-- This table stores temporary 6-digit codes sent to users via email.
CREATE TABLE IF NOT EXISTS public.account_deletion_otps (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    otp_code TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for public.account_deletion_otps
ALTER TABLE public.account_deletion_otps ENABLE ROW LEVEL SECURITY;

-- Policy: Deny all access to public/authenticated users (Managed by Service Role / Edge Functions)
-- By default, RLS blocks everything if no policies are defined. 
-- We explicitly define no policies here to ensure only the Service Role can access it.
