-- Force specific roles for key users
-- Note: users must sign in via Google first to create their auth.users record, 
-- or we can pre-provision if the profile exists.

DO $$
BEGIN
  -- 1. Super Admin: larsenevans@gmail.com
  UPDATE public.profiles SET role = 'admin' WHERE email = 'larsenevans@gmail.com';
  
  -- 2. Majiteľ: erikbabcan@gmail.com
  UPDATE public.profiles SET role = 'admin' WHERE email = 'erikbabcan@gmail.com';
  
  -- 3. Zákazník: enzoenzof2024@gmail.com
  UPDATE public.profiles SET role = 'customer' WHERE email = 'enzoenzof2024@gmail.com';
END
$$;
