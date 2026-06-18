-- ============================================================================
-- ADD MISSING TABLES FROM SUPABASE
-- ============================================================================
-- This migration adds tables that exist in Supabase but were missing from Git
-- These are critical business tables for:
-- - Driver verification (documents, earnings, bank accounts)
-- - Messaging system (messages)
-- - Zone management (operating_zones)
-- - Payment tracking (payouts)
-- - Promo codes (promo_codes, user_promos)
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. DRIVER DOCUMENTS (Verification, License, Insurance)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.driver_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL,
  document_type text NOT NULL CHECK (document_type = ANY (ARRAY['license'::text, 'insurance'::text, 'registration'::text, 'inspection'::text, 'background_check'::text])),
  document_url text,
  expiry_date date,
  verification_status text NOT NULL DEFAULT 'pending'::text CHECK (verification_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'expired'::text])),
  verified_at timestamp with time zone,
  verified_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT driver_documents_pkey PRIMARY KEY (id),
  CONSTRAINT driver_documents_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE
);

-- ============================================================================
-- 2. DRIVER EARNINGS (Income Tracking)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.driver_earnings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL,
  ride_id uuid,
  gross_amount numeric NOT NULL,
  commission_amount numeric NOT NULL,
  net_amount numeric NOT NULL,
  currency text DEFAULT 'EUR'::text,
  payment_status text NOT NULL DEFAULT 'pending'::text CHECK (payment_status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text])),
  created_at timestamp with time zone DEFAULT now(),
  paid_at timestamp with time zone,
  CONSTRAINT driver_earnings_pkey PRIMARY KEY (id),
  CONSTRAINT driver_earnings_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE,
  CONSTRAINT driver_earnings_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id) ON DELETE SET NULL
);

-- ============================================================================
-- 3. DRIVER BANK ACCOUNTS (Payout Details)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.driver_bank_accounts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL UNIQUE,
  account_holder_name text NOT NULL,
  bank_name text NOT NULL,
  iban text NOT NULL,
  bic text,
  account_status text NOT NULL DEFAULT 'pending'::text CHECK (account_status = ANY (ARRAY['pending'::text, 'verified'::text, 'rejected'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT driver_bank_accounts_pkey PRIMARY KEY (id),
  CONSTRAINT driver_bank_accounts_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE
);

-- ============================================================================
-- 4. MESSAGES (Rider-Driver Chat)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ride_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  recipient_id uuid NOT NULL,
  message_text text NOT NULL,
  attachment_url text,
  message_status text NOT NULL DEFAULT 'sent'::text CHECK (message_status = ANY (ARRAY['sent'::text, 'delivered'::text, 'read'::text])),
  created_at timestamp with time zone DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT messages_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 5. OPERATING ZONES (Service Areas)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.operating_zones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  zone_name text NOT NULL UNIQUE,
  city text NOT NULL,
  country text DEFAULT 'SK'::text,
  center_lat double precision NOT NULL,
  center_lng double precision NOT NULL,
  polygon jsonb NOT NULL,
  is_active boolean DEFAULT true,
  service_fee_percent numeric DEFAULT 10,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT operating_zones_pkey PRIMARY KEY (id)
);

-- ============================================================================
-- 6. PAYOUTS (Payment Transactions)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.payouts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL,
  amount numeric NOT NULL,
  currency text DEFAULT 'EUR'::text,
  payout_method text NOT NULL DEFAULT 'bank_transfer'::text CHECK (payout_method = ANY (ARRAY['bank_transfer'::text, 'wallet'::text, 'check'::text])),
  payout_status text NOT NULL DEFAULT 'pending'::text CHECK (payout_status = ANY (ARRAY['pending'::text, 'processing'::text, 'completed'::text, 'failed'::text])),
  transaction_reference text,
  created_at timestamp with time zone DEFAULT now(),
  processed_at timestamp with time zone,
  CONSTRAINT payouts_pkey PRIMARY KEY (id),
  CONSTRAINT payouts_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE
);

-- ============================================================================
-- 7. PROMO CODES (Marketing)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_type text NOT NULL CHECK (discount_type = ANY (ARRAY['percentage'::text, 'fixed_amount'::text])),
  discount_value numeric NOT NULL,
  max_uses integer,
  times_used integer DEFAULT 0,
  usage_limit_per_user integer DEFAULT 1,
  min_ride_value numeric,
  max_discount_amount numeric,
  valid_from timestamp with time zone NOT NULL,
  valid_until timestamp with time zone NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promo_codes_pkey PRIMARY KEY (id)
);

-- ============================================================================
-- 8. USER PROMOS (Promo Usage Tracking)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_promos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  promo_id uuid NOT NULL,
  ride_id uuid,
  discount_amount numeric NOT NULL,
  used_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_promos_pkey PRIMARY KEY (id),
  CONSTRAINT user_promos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT user_promos_promo_id_fkey FOREIGN KEY (promo_id) REFERENCES public.promo_codes(id) ON DELETE RESTRICT,
  CONSTRAINT user_promos_ride_id_fkey FOREIGN KEY (ride_id) REFERENCES public.rides(id) ON DELETE SET NULL
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS driver_documents_driver_id_idx ON public.driver_documents(driver_id);
CREATE INDEX IF NOT EXISTS driver_documents_verification_status_idx ON public.driver_documents(verification_status);

CREATE INDEX IF NOT EXISTS driver_earnings_driver_id_idx ON public.driver_earnings(driver_id);
CREATE INDEX IF NOT EXISTS driver_earnings_ride_id_idx ON public.driver_earnings(ride_id);
CREATE INDEX IF NOT EXISTS driver_earnings_payment_status_idx ON public.driver_earnings(payment_status);

CREATE INDEX IF NOT EXISTS driver_bank_accounts_driver_id_idx ON public.driver_bank_accounts(driver_id);

CREATE INDEX IF NOT EXISTS messages_ride_id_idx ON public.messages(ride_id);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_recipient_id_idx ON public.messages(recipient_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at DESC);

CREATE INDEX IF NOT EXISTS operating_zones_is_active_idx ON public.operating_zones(is_active);

CREATE INDEX IF NOT EXISTS payouts_driver_id_idx ON public.payouts(driver_id);
CREATE INDEX IF NOT EXISTS payouts_payout_status_idx ON public.payouts(payout_status);

CREATE INDEX IF NOT EXISTS promo_codes_is_active_idx ON public.promo_codes(is_active);
CREATE INDEX IF NOT EXISTS promo_codes_valid_until_idx ON public.promo_codes(valid_until);

CREATE INDEX IF NOT EXISTS user_promos_user_id_idx ON public.user_promos(user_id);
CREATE INDEX IF NOT EXISTS user_promos_promo_id_idx ON public.user_promos(promo_id);

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.driver_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operating_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_promos ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Driver Documents: Drivers see own, Admins see all
CREATE POLICY "Drivers see own documents" ON public.driver_documents FOR SELECT
  TO authenticated USING (
    driver_id = (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins see all documents" ON public.driver_documents FOR SELECT
  TO authenticated USING (private.is_admin());

-- Driver Earnings: Drivers see own, Admins see all
CREATE POLICY "Drivers see own earnings" ON public.driver_earnings FOR SELECT
  TO authenticated USING (
    driver_id = (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins see all earnings" ON public.driver_earnings FOR SELECT
  TO authenticated USING (private.is_admin());

-- Driver Bank Accounts: Drivers see own, Admins see all
CREATE POLICY "Drivers see own bank account" ON public.driver_bank_accounts FOR SELECT
  TO authenticated USING (
    driver_id = (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins see all bank accounts" ON public.driver_bank_accounts FOR SELECT
  TO authenticated USING (private.is_admin());

-- Messages: Users in conversation see messages
CREATE POLICY "Users see messages in their rides" ON public.messages FOR SELECT
  TO authenticated USING (
    sender_id = auth.uid() OR recipient_id = auth.uid() OR
    ride_id IN (
      SELECT id FROM public.rides 
      WHERE customer_id = auth.uid() 
         OR driver_id = (SELECT id FROM public.drivers WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Users can insert messages" ON public.messages FOR INSERT
  TO authenticated WITH CHECK (sender_id = auth.uid());

-- Operating Zones: Public read, Admins write
CREATE POLICY "Anyone see active zones" ON public.operating_zones FOR SELECT
  TO authenticated USING (is_active = true);

CREATE POLICY "Admins manage zones" ON public.operating_zones FOR ALL
  TO authenticated USING (private.is_admin());

-- Payouts: Drivers see own, Admins see all
CREATE POLICY "Drivers see own payouts" ON public.payouts FOR SELECT
  TO authenticated USING (
    driver_id = (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins see all payouts" ON public.payouts FOR SELECT
  TO authenticated USING (private.is_admin());

-- Promo Codes: Public read, Admins write
CREATE POLICY "Anyone see active promos" ON public.promo_codes FOR SELECT
  TO authenticated USING (is_active = true AND valid_until > now());

CREATE POLICY "Admins manage promos" ON public.promo_codes FOR ALL
  TO authenticated USING (private.is_admin());

-- User Promos: Users see own, Admins see all
CREATE POLICY "Users see own promo usage" ON public.user_promos FOR SELECT
  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Admins see all promo usage" ON public.user_promos FOR SELECT
  TO authenticated USING (private.is_admin());

COMMIT;
