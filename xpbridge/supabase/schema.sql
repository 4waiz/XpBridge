-- XPBridge production schema
-- Run in Supabase SQL editor for a fresh environment.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key,
  role text not null check (role in ('student', 'startup')),
  email text unique not null,
  name text,
  company_name text,
  phone text,
  bio text,
  description text,
  profile_image_url text,
  education text,
  skills text[] not null default '{}',
  availability_hours numeric not null default 0,
  portfolio_url text,
  github_url text,
  resume_url text,
  resume_file_name text,
  resume_mime_type text,
  xp_points integer not null default 0,
  level integer not null default 1,
  missions_completed_count integer not null default 0,
  website_url text,
  industry text,
  required_skills text[] not null default '{}',
  project_details text,
  logo_url text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  startup_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  commitment text,
  estimated_hours integer,
  duration_weeks integer,
  learning_outcome text not null default '',
  required_skills text[] not null default '{}',
  status text not null default 'open' check (status in ('open', 'closed')),
  team_config jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid references public.missions(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  startup_id uuid not null references public.profiles(id) on delete cascade,
  student_name text not null default '',
  startup_name text not null default '',
  role_title text,
  status text not null default 'pending'
    check (status in ('pending', 'interviewing', 'accepted', 'rejected', 'completed', 'hired')),
  message text,
  deliverable_url text,
  deliverable_type text,
  reflection_did text,
  reflection_learned text,
  skills_practiced text[] not null default '{}',
  hours_spent integer,
  mentor_rating integer,
  mentor_feedback_text text,
  strengths text[] not null default '{}',
  growth_areas text[] not null default '{}',
  endorsed_skills text[] not null default '{}',
  applied_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  feedback_at timestamptz
);

create unique index if not exists applications_student_mission_unique
  on public.applications(student_id, mission_id)
  where mission_id is not null;

create table if not exists public.ai_interviews (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique references public.applications(id) on delete cascade,
  mission_id uuid references public.missions(id) on delete set null,
  student_id uuid not null references public.profiles(id) on delete cascade,
  startup_id uuid not null references public.profiles(id) on delete cascade,
  questions jsonb not null default '[]'::jsonb,
  responses jsonb not null default '[]'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'inProgress', 'completed')),
  summary text,
  recommendation text,
  communication_score integer,
  confidence_score integer,
  relevance_score integer,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and is_admin = true
  );
$$;

alter table public.profiles enable row level security;
alter table public.missions enable row level security;
alter table public.applications enable row level security;
alter table public.ai_interviews enable row level security;

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated" on public.profiles
  for select
  using (auth.uid() is not null);

drop policy if exists "profiles_manage_self_or_admin" on public.profiles;
create policy "profiles_manage_self_or_admin" on public.profiles
  for all
  using (auth.uid() = id or public.is_admin())
  with check (auth.uid() = id or public.is_admin());

drop policy if exists "missions_select_open_or_owned_or_admin" on public.missions;
create policy "missions_select_open_or_owned_or_admin" on public.missions
  for select
  using (status = 'open' or auth.uid() = startup_id or public.is_admin());

drop policy if exists "missions_manage_owned_or_admin" on public.missions;
create policy "missions_manage_owned_or_admin" on public.missions
  for all
  using (auth.uid() = startup_id or public.is_admin())
  with check (auth.uid() = startup_id or public.is_admin());

drop policy if exists "applications_insert_student_or_admin" on public.applications;
create policy "applications_insert_student_or_admin" on public.applications
  for insert
  with check (auth.uid() = student_id or public.is_admin());

drop policy if exists "applications_select_related_or_admin" on public.applications;
create policy "applications_select_related_or_admin" on public.applications
  for select
  using (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  );

drop policy if exists "applications_update_related_or_admin" on public.applications;
create policy "applications_update_related_or_admin" on public.applications
  for update
  using (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  )
  with check (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  );

drop policy if exists "applications_delete_admin" on public.applications;
create policy "applications_delete_admin" on public.applications
  for delete
  using (public.is_admin());

drop policy if exists "ai_interviews_select_related_or_admin" on public.ai_interviews;
create policy "ai_interviews_select_related_or_admin" on public.ai_interviews
  for select
  using (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  );

drop policy if exists "ai_interviews_insert_startup_or_admin" on public.ai_interviews;
create policy "ai_interviews_insert_startup_or_admin" on public.ai_interviews
  for insert
  with check (auth.uid() = startup_id or public.is_admin());

drop policy if exists "ai_interviews_update_related_or_admin" on public.ai_interviews;
create policy "ai_interviews_update_related_or_admin" on public.ai_interviews
  for update
  using (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  )
  with check (
    auth.uid() = student_id
    or auth.uid() = startup_id
    or public.is_admin()
  );

alter publication supabase_realtime add table public.missions;
alter publication supabase_realtime add table public.applications;
alter publication supabase_realtime add table public.ai_interviews;

-- Storage bucket setup is still required in Supabase dashboard or via SQL:
-- insert into storage.buckets (id, name, public) values ('xpbridge-assets', 'xpbridge-assets', true);
