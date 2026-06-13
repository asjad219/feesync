-- Migration: 026_create_or_verify_subscriptions.sql
-- Created: 2026-06-13
-- Description: Create or verify subscriptions table columns, limits, and helper functions

BEGIN;

-- 1. Alter subscriptions table columns if they exist
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_plan_tier_check;

DO $$ 
BEGIN
  -- Rename owner_id to user_id if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscriptions' AND column_name = 'owner_id') THEN
    ALTER TABLE subscriptions RENAME COLUMN owner_id TO user_id;
  END IF;

  -- Rename plan_tier to plan_type if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscriptions' AND column_name = 'plan_tier') THEN
    ALTER TABLE subscriptions RENAME COLUMN plan_tier TO plan_type;
  END IF;

  -- Rename valid_until to expiry_date if it exists
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscriptions' AND column_name = 'valid_until') THEN
    ALTER TABLE subscriptions RENAME COLUMN valid_until TO expiry_date;
  END IF;
END $$;

-- 2. Ensure new columns status and start_date exist with default values
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 3. Update defaults and constraints
ALTER TABLE subscriptions ALTER COLUMN plan_type SET DEFAULT 'free';
ALTER TABLE subscriptions ALTER COLUMN status SET DEFAULT 'active';

ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_plan_type_check;
ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_plan_type_check CHECK (plan_type IN ('free', 'starter', 'growth', 'institute'));

ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS subscriptions_status_check;
ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'inactive', 'past_due', 'paused', 'cancelled'));

-- 4. Recreate Indexes
DROP INDEX IF EXISTS idx_subscriptions_owner_id;
DROP INDEX IF EXISTS idx_subscriptions_plan_tier;
DROP INDEX IF EXISTS idx_subscriptions_valid_until;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_type ON subscriptions(plan_type);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expiry_date ON subscriptions(expiry_date);

-- 5. Recreate RLS Policies using user_id instead of owner_id
DROP POLICY IF EXISTS "Owner can view own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Owner can update own subscription" ON subscriptions;
DROP POLICY IF EXISTS "Owner can insert own subscription" ON subscriptions;

CREATE POLICY "Owner can view own subscription"
  ON subscriptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Owner can update own subscription"
  ON subscriptions FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Owner can insert own subscription"
  ON subscriptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- 6. Update helper functions with new plan limits
CREATE OR REPLACE FUNCTION get_plan_limits(p_tier TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT CASE p_tier
    WHEN 'free'      THEN '{"max_students":20,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":1}'::jsonb
    WHEN 'starter'   THEN '{"max_students":200,"max_batches":10,"wa_receipts":1000,"wa_reminders":-1,"sms":100,"max_staff":5}'::jsonb
    WHEN 'growth'    THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":500,"max_staff":-1}'::jsonb
    WHEN 'institute' THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":1000,"max_staff":-1}'::jsonb
    ELSE             '{"max_students":20,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":1}'::jsonb
  END;
$$;

-- 7. Update upsert_subscription function
CREATE OR REPLACE FUNCTION upsert_subscription(
  p_owner_id            UUID,
  p_plan_tier           TEXT,
  p_billing_cycle       TEXT,
  p_valid_until         TIMESTAMPTZ,
  p_google_play_token   TEXT DEFAULT NULL,
  p_google_play_product TEXT DEFAULT NULL,
  p_razorpay_sub_id     TEXT DEFAULT NULL,
  p_razorpay_payment_id TEXT DEFAULT NULL
)
RETURNS subscriptions
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limits JSONB;
  v_row    subscriptions;
BEGIN
  v_limits := get_plan_limits(p_plan_tier);

  INSERT INTO subscriptions (
    user_id,
    plan_type,
    billing_cycle,
    expiry_date,
    max_students,
    max_batches,
    whatsapp_receipts_limit,
    whatsapp_reminders_limit,
    sms_limit,
    max_staff,
    google_play_purchase_token,
    google_play_product_id,
    razorpay_sub_id,
    razorpay_payment_id,
    status,
    start_date
  ) VALUES (
    p_owner_id,
    p_plan_tier,
    p_billing_cycle,
    p_valid_until,
    (v_limits->>'max_students')::integer,
    (v_limits->>'max_batches')::integer,
    (v_limits->>'wa_receipts')::integer,
    (v_limits->>'wa_reminders')::integer,
    (v_limits->>'sms')::integer,
    (v_limits->>'max_staff')::integer,
    p_google_play_token,
    p_google_play_product,
    p_razorpay_sub_id,
    p_razorpay_payment_id,
    'active',
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    plan_type                  = EXCLUDED.plan_type,
    billing_cycle              = EXCLUDED.billing_cycle,
    expiry_date                = EXCLUDED.expiry_date,
    max_students               = EXCLUDED.max_students,
    max_batches                = EXCLUDED.max_batches,
    whatsapp_receipts_limit    = EXCLUDED.whatsapp_receipts_limit,
    whatsapp_reminders_limit   = EXCLUDED.whatsapp_reminders_limit,
    sms_limit                  = EXCLUDED.sms_limit,
    max_staff                  = EXCLUDED.max_staff,
    google_play_purchase_token = COALESCE(EXCLUDED.google_play_purchase_token, subscriptions.google_play_purchase_token),
    google_play_product_id     = COALESCE(EXCLUDED.google_play_product_id,     subscriptions.google_play_product_id),
    razorpay_sub_id            = COALESCE(EXCLUDED.razorpay_sub_id,            subscriptions.razorpay_sub_id),
    razorpay_payment_id        = COALESCE(EXCLUDED.razorpay_payment_id,        subscriptions.razorpay_payment_id),
    status                     = EXCLUDED.status,
    updated_at                 = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMIT;
