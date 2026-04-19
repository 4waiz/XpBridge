-- =============================================
-- XPBridge: Storage bucket + RLS policies for `xpbridge-assets`.
--
-- Run once in Supabase Dashboard → SQL Editor → New Query → Run.
-- Safe to re-run: policies are dropped before re-creation.
--
-- Final layout inside the bucket:
--   resumes/<auth-uid>/<file>        → user CV
--   profiles/<auth-uid>/<file>       → user/startup avatar
--   logos/<auth-uid>/<file>          → startup logo
--
-- Public download (read-by-URL) is served by the bucket's public flag and
-- bypasses RLS, so we do NOT add a blanket `anon/public SELECT` policy
-- (that policy made every object *listable*, which is the warning the
-- project received).
-- =============================================

-- 1. Ensure the bucket exists and is public (public = files are reachable
--    via /storage/v1/object/public/... without an Authorization header).
insert into storage.buckets (id, name, public)
values ('xpbridge-assets', 'xpbridge-assets', true)
on conflict (id) do update
set public = excluded.public;

-- 2. Drop any legacy/overly broad policies so we start from a clean slate.
drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Authenticated users can upload" on storage.objects;
drop policy if exists "Users can delete their own assets" on storage.objects;
drop policy if exists "Users can update their own assets" on storage.objects;
drop policy if exists "Give users authenticated access to folder 1c6f90w_0" on storage.objects;
drop policy if exists "storage_select_own_resume_or_logo" on storage.objects;
drop policy if exists "storage_insert_own_resume_or_logo" on storage.objects;
drop policy if exists "storage_update_own_resume_or_logo" on storage.objects;
drop policy if exists "storage_delete_own_resume_or_logo" on storage.objects;
drop policy if exists "xpbridge_assets_owner_select" on storage.objects;
drop policy if exists "xpbridge_assets_owner_insert" on storage.objects;
drop policy if exists "xpbridge_assets_owner_update" on storage.objects;
drop policy if exists "xpbridge_assets_owner_delete" on storage.objects;

-- 3. Tight, per-user policies. A user may only touch objects under their
--    own <uid>/ folder inside the three known top-level folders. Nothing
--    else is authorised through the authenticated API.
create policy "xpbridge_assets_owner_select"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/'  || auth.uid()::text || '/%'
    or name like 'profiles/' || auth.uid()::text || '/%'
    or name like 'logos/'    || auth.uid()::text || '/%'
  )
);

create policy "xpbridge_assets_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/'  || auth.uid()::text || '/%'
    or name like 'profiles/' || auth.uid()::text || '/%'
    or name like 'logos/'    || auth.uid()::text || '/%'
  )
);

create policy "xpbridge_assets_owner_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/'  || auth.uid()::text || '/%'
    or name like 'profiles/' || auth.uid()::text || '/%'
    or name like 'logos/'    || auth.uid()::text || '/%'
  )
)
with check (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/'  || auth.uid()::text || '/%'
    or name like 'profiles/' || auth.uid()::text || '/%'
    or name like 'logos/'    || auth.uid()::text || '/%'
  )
);

create policy "xpbridge_assets_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'xpbridge-assets'
  and (
    name like 'resumes/'  || auth.uid()::text || '/%'
    or name like 'profiles/' || auth.uid()::text || '/%'
    or name like 'logos/'    || auth.uid()::text || '/%'
  )
);
