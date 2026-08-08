-- 01_schema_and_tables.sql
-- Create role type enum
create type public.app_role as enum (
  'student',
  'class_teacher',
  'super_admin'
);

-- Profiles table (extends auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  full_name text not null,
  email text,
  phone text,
  role public.app_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Classes table
create table public.classes (
  id uuid primary key default gen_random_uuid(),
  class_name text not null,
  section text,
  academic_year text not null,
  class_teacher_id uuid unique references public.profiles(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Students table
create table public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  admission_number text unique not null,
  roll_number text not null,
  full_name text not null,
  class_id uuid not null references public.classes(id),
  date_of_birth date,
  gender text,
  guardian_name text,
  guardian_phone text,
  address text,
  photo_path text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(class_id, roll_number)
);

-- Teachers table
create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique not null references public.profiles(id) on delete cascade,
  employee_number text unique,
  qualification text,
  joined_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Subjects table
create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  subject_name text not null,
  subject_code text,
  class_id uuid not null references public.classes(id),
  maximum_marks numeric not null default 100,
  pass_marks numeric not null default 35,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Exams table
create table public.exams (
  id uuid primary key default gen_random_uuid(),
  exam_name text not null,
  term text,
  class_id uuid not null references public.classes(id),
  exam_center text,
  reporting_time time,
  start_date date,
  end_date date,
  results_published boolean not null default false,
  hall_ticket_locked boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Exam Subjects table
create table public.exam_subjects (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  subject_id uuid not null references public.subjects(id),
  exam_date date,
  start_time time,
  end_time time,
  maximum_marks numeric not null default 100,
  pass_marks numeric not null default 35,
  unique(exam_id, subject_id)
);

-- Results table
create table public.results (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id),
  marks_obtained numeric,
  maximum_marks numeric not null default 100,
  grade text,
  result_status text,
  remarks text,
  is_published boolean not null default false,
  published_at timestamptz,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(exam_id, student_id, subject_id)
);

-- Notes table
create table public.notes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  class_id uuid not null references public.classes(id),
  subject_id uuid references public.subjects(id),
  teacher_id uuid references public.profiles(id),
  file_path text not null,
  file_name text,
  file_size bigint,
  is_published boolean not null default true,
  uploaded_at timestamptz not null default now()
);

-- Hall Tickets table
create table public.hall_tickets (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.exams(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  hall_ticket_number text unique not null,
  status text not null default 'generated',
  generated_at timestamptz not null default now(),
  locked_at timestamptz,
  file_path text,
  unique(exam_id, student_id)
);

-- Announcements table
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null,
  target_type text not null default 'all',
  target_class_id uuid references public.classes(id),
  published_by uuid references public.profiles(id),
  published_at timestamptz not null default now(),
  expires_at timestamptz,
  is_active boolean not null default true
);

-- Activity Logs table
create table public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  description text,
  class_id uuid references public.classes(id),
  created_at timestamptz not null default now()
);

-- App Settings table
create table public.app_settings (
  id uuid primary key default gen_random_uuid(),
  setting_key text unique not null,
  setting_value jsonb,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

-- Updated_at triggers setup
create or replace function public.handle_update_timestamp()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger tr_profiles_updated_at before update on public.profiles for each row execute procedure public.handle_update_timestamp();
create trigger tr_classes_updated_at before update on public.classes for each row execute procedure public.handle_update_timestamp();
create trigger tr_students_updated_at before update on public.students for each row execute procedure public.handle_update_timestamp();
create trigger tr_teachers_updated_at before update on public.teachers for each row execute procedure public.handle_update_timestamp();
create trigger tr_exams_updated_at before update on public.exams for each row execute procedure public.handle_update_timestamp();
create trigger tr_results_updated_at before update on public.results for each row execute procedure public.handle_update_timestamp();
create trigger tr_app_settings_updated_at before update on public.app_settings for each row execute procedure public.handle_update_timestamp();
