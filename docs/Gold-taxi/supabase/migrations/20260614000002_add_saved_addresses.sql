-- SUPABASE MIGRATION SQL for Gold-Taxi
-- Phase 5A: Add saved_addresses JSONB column to profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS saved_addresses JSONB DEFAULT '{}'::jsonb;

-- RLS policy for profile updates
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile' AND tablename = 'profiles') THEN
        CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
    END IF;
END
$$;

