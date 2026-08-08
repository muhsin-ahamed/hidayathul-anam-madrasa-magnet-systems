-- 02_helpers_and_rls.sql

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.teachers enable row level security;
alter table public.subjects enable row level security;
alter table public.exams enable row level security;
alter table public.exam_subjects enable row level security;
alter table public.results enable row level security;
alter table public.notes enable row level security;
alter table public.hall_tickets enable row level security;
alter table public.announcements enable row level security;
alter table public.activity_logs enable row level security;
alter table public.app_settings enable row level security;

-- Create helper functions with security definer and fixed search_path
create or replace function public.get_email_by_username(p_username text)
returns text security definer set search_path = public as $$
begin
  return (
    select p.email
    from public.profiles p
    left join public.students s on s.profile_id = p.id
    where lower(p.username) = lower(p_username)
       or lower(p.email) = lower(p_username)
       or lower(s.admission_number) = lower(p_username)
    limit 1
  );
end;
$$ language plpgsql;

create or replace function public.is_super_admin()
returns boolean security definer set search_path = public as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'super_admin'
      and is_active = true
  );
end;
$$ language plpgsql;

create or replace function public.is_class_teacher()
returns boolean security definer set search_path = public as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'class_teacher'
      and is_active = true
  );
end;
$$ language plpgsql;

create or replace function public.current_teacher_class_id()
returns uuid security definer set search_path = public as $$
begin
  return (
    select id from public.classes
    where class_teacher_id = auth.uid()
    limit 1
  );
end;
$$ language plpgsql;

create or replace function public.current_student_id()
returns uuid security definer set search_path = public as $$
begin
  return (
    select id from public.students
    where profile_id = auth.uid()
      and is_active = true
    limit 1
  );
end;
$$ language plpgsql;

-- RLS Policies

-- PROFILES
create policy "Allow select profiles" on public.profiles
  for select using (
    id = auth.uid()
    or is_super_admin()
    or (
      is_class_teacher()
      and exists (
        select 1 from public.students s
        where s.profile_id = profiles.id
          and s.class_id = current_teacher_class_id()
      )
    )
  );

create policy "Allow all for super_admin on profiles" on public.profiles
  for all using (is_super_admin()) with check (is_super_admin());

-- CLASSES
create policy "Allow select classes for authenticated" on public.classes
  for select using (auth.role() = 'authenticated');

create policy "Allow all for super_admin on classes" on public.classes
  for all using (is_super_admin()) with check (is_super_admin());

-- STUDENTS
create policy "Allow select students" on public.students
  for select using (
    profile_id = auth.uid()
    or is_super_admin()
    or (is_class_teacher() and class_id = current_teacher_class_id())
  );

create policy "Allow insert/update/delete students for super admin" on public.students
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage students for class teacher" on public.students
  for all using (
    is_class_teacher() and class_id = current_teacher_class_id()
  ) with check (
    is_class_teacher() and class_id = current_teacher_class_id()
  );

-- TEACHERS
create policy "Allow select teachers" on public.teachers
  for select using (
    profile_id = auth.uid()
    or is_super_admin()
    or is_class_teacher() -- Allow class teachers to view teachers
  );

create policy "Allow all for super_admin on teachers" on public.teachers
  for all using (is_super_admin()) with check (is_super_admin());

-- SUBJECTS
create policy "Allow select subjects" on public.subjects
  for select using (
    is_super_admin()
    or (is_class_teacher() and class_id = current_teacher_class_id())
    or class_id = (select class_id from public.students where profile_id = auth.uid())
  );

create policy "Allow all for super_admin on subjects" on public.subjects
  for all using (is_super_admin()) with check (is_super_admin());

-- EXAMS
create policy "Allow select exams" on public.exams
  for select using (
    is_super_admin()
    or (is_class_teacher() and class_id = current_teacher_class_id())
    or class_id = (select class_id from public.students where profile_id = auth.uid())
  );

create policy "Allow all for super admin on exams" on public.exams
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage exams for class teacher" on public.exams
  for all using (
    is_class_teacher() and class_id = current_teacher_class_id()
  ) with check (
    is_class_teacher() and class_id = current_teacher_class_id()
  );

-- EXAM SUBJECTS
create policy "Allow select exam_subjects" on public.exam_subjects
  for select using (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and (
          is_super_admin()
          or (is_class_teacher() and e.class_id = current_teacher_class_id())
          or e.class_id = (select class_id from public.students where profile_id = auth.uid())
        )
    )
  );

create policy "Allow all for super admin on exam_subjects" on public.exam_subjects
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage exam_subjects for class teacher" on public.exam_subjects
  for all using (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and is_class_teacher()
        and e.class_id = current_teacher_class_id()
    )
  ) with check (
    exists (
      select 1 from public.exams e
      where e.id = exam_id
        and is_class_teacher()
        and e.class_id = current_teacher_class_id()
    )
  );

-- RESULTS
create policy "Allow select results" on public.results
  for select using (
    is_super_admin()
    or (
      is_class_teacher()
      and student_id in (select id from public.students where class_id = current_teacher_class_id())
    )
    or (
      is_published = true
      and student_id = current_student_id()
    )
  );

create policy "Allow all for super admin on results" on public.results
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage results for class teacher" on public.results
  for all using (
    is_class_teacher()
    and student_id in (select id from public.students where class_id = current_teacher_class_id())
  ) with check (
    is_class_teacher()
    and student_id in (select id from public.students where class_id = current_teacher_class_id())
  );

-- NOTES
create policy "Allow select notes" on public.notes
  for select using (
    is_super_admin()
    or (is_class_teacher() and class_id = current_teacher_class_id())
    or (
      is_published = true
      and class_id = (select class_id from public.students where profile_id = auth.uid())
    )
  );

create policy "Allow all for super admin on notes" on public.notes
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage notes for class teacher" on public.notes
  for all using (
    is_class_teacher() and class_id = current_teacher_class_id()
  ) with check (
    is_class_teacher() and class_id = current_teacher_class_id()
  );

-- HALL TICKETS
create policy "Allow select hall_tickets" on public.hall_tickets
  for select using (
    is_super_admin()
    or student_id in (select id from public.students where class_id = current_teacher_class_id())
    or (
      student_id = current_student_id()
      and exists (
        select 1 from public.exams e
        where e.id = exam_id
          and e.hall_ticket_locked = false
      )
    )
  );

create policy "Allow all for super admin on hall_tickets" on public.hall_tickets
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage hall_tickets for class teacher" on public.hall_tickets
  for all using (
    is_class_teacher()
    and student_id in (select id from public.students where class_id = current_teacher_class_id())
  ) with check (
    is_class_teacher()
    and student_id in (select id from public.students where class_id = current_teacher_class_id())
  );

-- ANNOUNCEMENTS
create policy "Allow select announcements" on public.announcements
  for select using (
    is_super_admin()
    or is_class_teacher()
    or (
      is_active = true
      and (
        target_type = 'all'
        or target_type = 'students'
        or (target_type = 'class' and target_class_id = (select class_id from public.students where profile_id = auth.uid()))
      )
    )
  );

create policy "Allow all for super admin on announcements" on public.announcements
  for all using (is_super_admin()) with check (is_super_admin());

create policy "Allow manage announcements for class teacher" on public.announcements
  for all using (
    is_class_teacher()
    and target_type = 'class'
    and target_class_id = current_teacher_class_id()
  ) with check (
    is_class_teacher()
    and target_type = 'class'
    and target_class_id = current_teacher_class_id()
  );

-- ACTIVITY LOGS
create policy "Allow select activity_logs" on public.activity_logs
  for select using (
    is_super_admin()
    or (is_class_teacher() and class_id = current_teacher_class_id())
  );

create policy "Allow insert activity_logs for authenticated" on public.activity_logs
  for insert with check (auth.role() = 'authenticated');

-- APP SETTINGS
create policy "Allow select app_settings for authenticated" on public.app_settings
  for select using (auth.role() = 'authenticated');

create policy "Allow all for super admin on app_settings" on public.app_settings
  for all using (is_super_admin()) with check (is_super_admin());


-- STORAGE POLICIES
-- To run: setup storage buckets in dashboard first. These policies control access to:
-- student-photos, study-notes, hall-tickets, result-imports, announcement-files

-- student-photos: read for self, class teacher, admin. write for admin & class teacher.
-- study-notes: read for student of same class, teacher of same class, admin. write for teacher & admin.
-- hall-tickets: read for self (if not locked), teacher of class, admin. write for teacher & admin.
-- result-imports: read/write only for admin & class teacher.
-- announcement-files: read for anyone authenticated. write for admin & class teacher.
