-- ============================================================================
-- UoM UIP Student Hub — Production Supabase Schema (@uom.lk Auth + Admin Role)
-- Admin Email: bandarahmsh.25@uom.lk
-- Paste this entire file into Supabase > SQL Editor > New Query > Run
-- ============================================================================

-- 1. PROFILES TABLE (extends Supabase auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  display_name text,
  academic_level int check (academic_level between 1 and 4) default 1,
  role text check (role in ('student', 'rep', 'admin')) default 'student',
  created_at timestamptz default now()
);

-- 2. ENFORCE @uom.lk EMAILS & AUTO-ASSIGN ADMIN ROLE FOR bandarahmsh.25@uom.lk
create or replace function public.handle_new_uom_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  assigned_role text := 'student';
begin
  if lower(new.email) not like '%@uom.lk' then
    raise exception 'Only University of Moratuwa (@uom.lk) email addresses are permitted.';
  end if;

  if lower(new.email) = 'bandarahmsh.25@uom.lk' then
    assigned_role := 'admin';
  end if;

  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    lower(new.email),
    split_part(new.email, '@', 1),
    assigned_role
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_uom_user();

-- Ensure existing profile (if already created) is promoted to admin
update public.profiles
set role = 'admin'
where lower(email) = 'bandarahmsh.25@uom.lk';

-- 3. MODULE RESOURCES TABLE (Notes, Past Papers, GIS Tutorials, Lab Sheets)
create table if not exists public.resources (
  id bigint generated always as identity primary key,
  module_code text not null, -- e.g. 'PL1206'
  title text not null,
  category text check (category in ('Notes', 'Past Paper', 'GIS Tutorial', 'Lab Sheet')) not null,
  drive_url text not null,
  contributor_id uuid references public.profiles(id) on delete set null,
  approved boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_resources_module on public.resources(module_code);

-- 4. PERSONAL GIS & TECH PROGRESS TABLE (syncs mastered tech modules per student)
create table if not exists public.user_gis_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  module_code text not null,
  completed_at timestamptz default now(),
  primary key (user_id, module_code)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) — @uom.lk Students + Full Admin Privileges
-- ============================================================================
alter table public.profiles enable row level security;
alter table public.resources enable row level security;
alter table public.user_gis_progress enable row level security;

create or replace function public.is_uom_student()
returns boolean
language sql
stable
as $$
  select auth.role() = 'authenticated'
     and lower(coalesce(auth.jwt() ->> 'email', '')) like '%@uom.lk';
$$;

create or replace function public.is_uom_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select auth.role() = 'authenticated'
     and (
       lower(coalesce(auth.jwt() ->> 'email', '')) = 'bandarahmsh.25@uom.lk'
       or exists (
         select 1 from public.profiles
         where id = auth.uid() and role = 'admin'
       )
     );
$$;

-- Drop old policies safely so this script can be re-run cleanly
drop policy if exists "UoM students can view profiles" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Admin can update any profile" on public.profiles;
drop policy if exists "UoM students can view approved resources" on public.resources;
drop policy if exists "UoM students can submit resources" on public.resources;
drop policy if exists "Contributors can delete own resources" on public.resources;
drop policy if exists "Admin can update any resource" on public.resources;
drop policy if exists "Admin or contributor can delete resources" on public.resources;
drop policy if exists "Users can view own GIS progress" on public.user_gis_progress;
drop policy if exists "Users can save own GIS progress" on public.user_gis_progress;
drop policy if exists "Users can remove own GIS progress" on public.user_gis_progress;

-- Profiles policies
create policy "UoM students can view profiles"
  on public.profiles for select
  using (public.is_uom_student());

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admin can update any profile"
  on public.profiles for update
  using (public.is_uom_admin());

-- Resources policies
create policy "UoM students can view approved resources"
  on public.resources for select
  using (public.is_uom_student() and (approved = true or public.is_uom_admin()));

create policy "UoM students can submit resources"
  on public.resources for insert
  with check (public.is_uom_student() and auth.uid() = contributor_id);

create policy "Admin can update any resource"
  on public.resources for update
  using (public.is_uom_admin());

create policy "Admin or contributor can delete resources"
  on public.resources for delete
  using (auth.uid() = contributor_id or public.is_uom_admin());

-- GIS Progress policies
create policy "Users can view own GIS progress"
  on public.user_gis_progress for select
  using (auth.uid() = user_id or public.is_uom_admin());

create policy "Users can save own GIS progress"
  on public.user_gis_progress for insert
  with check (public.is_uom_student() and auth.uid() = user_id);

create policy "Users can remove own GIS progress"
  on public.user_gis_progress for delete
  using (auth.uid() = user_id);
