-- Disable Row Level Security on all database tables since all access goes through Node.js backend
ALTER TABLE IF EXISTS "profiles" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "students" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "teachers" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "classes" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "subjects" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "exams" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "results" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "notes" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "hall_tickets" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "announcements" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "app_settings" DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS "activity_logs" DISABLE ROW LEVEL SECURITY;

-- Drop any existing RLS policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "profiles";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "students";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "teachers";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "classes";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "subjects";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "exams";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "results";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "notes";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "hall_tickets";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "announcements";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "app_settings";
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON "activity_logs";
