-- 05_node_auth.sql

-- 1. Drop the foreign key constraint on profiles that links to auth.users
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 2. Create the new users table for Node.js authentication
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  role public.app_role NOT NULL,
  profile_id uuid UNIQUE NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Link users.profile_id to profiles.id with ON DELETE CASCADE
  CONSTRAINT fk_users_profile FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- 3. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_profile_id ON public.users(profile_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- 4. Add updated_at trigger for users table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'tr_users_updated_at') THEN
    CREATE TRIGGER tr_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE PROCEDURE public.handle_update_timestamp();
  END IF;
END
$$;
