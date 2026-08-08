-- 03_fix_auth_and_schema.sql

-- 1. Add is_active to public.teachers table if missing
alter table public.teachers add column if not exists is_active boolean not null default true;

-- 2. Update students.profile_id constraint to ON DELETE CASCADE
alter table public.students drop constraint if exists students_profile_id_fkey;
alter table public.students add constraint students_profile_id_fkey 
  foreign key (profile_id) references public.profiles(id) on delete cascade;

-- 3. Update classes.class_teacher_id constraint to ON DELETE SET NULL
alter table public.classes drop constraint if exists classes_class_teacher_id_fkey;
alter table public.classes add constraint classes_class_teacher_id_fkey 
  foreign key (class_teacher_id) references public.profiles(id) on delete set null;

-- 4. Enhanced get_email_by_username RPC
create or replace function public.get_email_by_username(p_username text)
returns text security definer set search_path = public as $$
begin
  return (
    select p.email
    from public.profiles p
    left join public.students s on s.profile_id = p.id
    left join public.teachers t on t.profile_id = p.id
    where lower(p.username) = lower(trim(p_username))
       or lower(p.email) = lower(trim(p_username))
       or lower(s.admission_number) = lower(trim(p_username))
       or lower(t.employee_number) = lower(trim(p_username))
       or lower(split_part(p.email, '@', 1)) = lower(trim(p_username))
    limit 1
  );
end;
$$ language plpgsql;

-- 5. Updated RLS Policies on profiles
drop policy if exists "Allow select profiles" on public.profiles;
create policy "Allow select profiles" on public.profiles
  for select using (
    id = auth.uid()
    or is_super_admin()
    or is_class_teacher()
  );

-- 6. Updated RLS Policies for authenticated users
drop policy if exists "Allow select classes for authenticated" on public.classes;
create policy "Allow select classes for authenticated" on public.classes
  for select to authenticated using (true);

drop policy if exists "Allow insert activity_logs for authenticated" on public.activity_logs;
create policy "Allow insert activity_logs for authenticated" on public.activity_logs
  for insert to authenticated with check (true);

drop policy if exists "Allow select app_settings for authenticated" on public.app_settings;
create policy "Allow select app_settings for authenticated" on public.app_settings
  for select to authenticated using (true);
