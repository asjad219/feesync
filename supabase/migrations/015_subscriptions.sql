-- Migration: 015_subscriptions.sql
-- Created: 2026-06-06
-- Description: Create subscriptions table for SaaS plan management

BEGIN;

-- ============================================
-- TABLE: subscriptions
-- ============================================
-- One row per owner (coach/admin). Tracks their plan tier,
-- validity, limits, and payment tokens from Google Play / Razorpay.

CREATE TABLE IF NOT EXISTS subscriptions (
  id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                    UUID        NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_tier                   TEXT        NOT NULL DEFAULT 'free'
                                          CHECK (plan_tier IN ('free', 'starter', 'growth', 'institute')),
  billing_cycle               TEXT        DEFAULT 'monthly'
                                          CHECK (billing_cycle IN ('monthly', 'annual')),
  valid_until                 TIMESTAMPTZ,
  -- Plan limits (stored so they can be overridden by admin if needed)
  max_students                INTEGER     NOT NULL DEFAULT 30,
  max_batches                 INTEGER     NOT NULL DEFAULT 2,
  whatsapp_receipts_limit     INTEGER     DEFAULT 100,   -- -1 = unlimited
  whatsapp_reminders_limit    INTEGER     DEFAULT 30,    -- -1 = unlimited
  sms_limit                   INTEGER     DEFAULT 0,     -- -1 = unlimited
  -- Payment provider tokens
  razorpay_sub_id             TEXT,
  razorpay_payment_id         TEXT,
  google_play_purchase_token  TEXT,
  google_play_product_id      TEXT,
  -- Trial
  trial_ends_at               TIMESTAMPTZ,
  is_trial                    BOOLEAN     DEFAULT false,
  -- Metadata
  created_at                  TIMESTAMPTZ DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TRIGGER: updated_at
-- ============================================
DO $$ BEGIN
  CREATE TRIGGER subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_subscriptions_owner_id    ON subscriptions(owner_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_tier   ON subscriptions(plan_tier);
CREATE INDEX IF NOT EXISTS idx_subscriptions_valid_until ON subscriptions(valid_until);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Owner can read their own subscription
CREATE POLICY "Owner can view own subscription"
  ON subscriptions FOR SELECT
  USING (owner_id = auth.uid());

-- Owner can update their own subscription (e.g. from billing webhook)
CREATE POLICY "Owner can update own subscription"
  ON subscriptions FOR UPDATE
  USING (owner_id = auth.uid());

-- Owner can insert their own subscription (first-time creation)
CREATE POLICY "Owner can insert own subscription"
  ON subscriptions FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- ============================================
-- HELPER FUNCTION: get_plan_limits
-- Returns JSON with limits for a given plan tier.
-- ============================================
CREATE OR REPLACE FUNCTION get_plan_limits(p_tier TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT CASE p_tier
    WHEN 'free'      THEN '{"max_students":30,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0}'::jsonb
    WHEN 'starter'   THEN '{"max_students":200,"max_batches":15,"wa_receipts":-1,"wa_reminders":-1,"sms":100}'::jsonb
    WHEN 'growth'    THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":500}'::jsonb
    WHEN 'institute' THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":1000}'::jsonb
    ELSE             '{"max_students":30,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0}'::jsonb
  END;
$$;

-- ============================================
-- HELPER FUNCTION: upsert_subscription
-- Called by billing webhook to create or update a user's plan.
-- ============================================
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
    owner_id,
    plan_tier,
    billing_cycle,
    valid_until,
    max_students,
    max_batches,
    whatsapp_receipts_limit,
    whatsapp_reminders_limit,
    sms_limit,
    google_play_purchase_token,
    google_play_product_id,
    razorpay_sub_id,
    razorpay_payment_id
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
    p_google_play_token,
    p_google_play_product,
    p_razorpay_sub_id,
    p_razorpay_payment_id
  )
  ON CONFLICT (owner_id) DO UPDATE SET
    plan_tier                  = EXCLUDED.plan_tier,
    billing_cycle              = EXCLUDED.billing_cycle,
    valid_until                = EXCLUDED.valid_until,
    max_students               = EXCLUDED.max_students,
    max_batches                = EXCLUDED.max_batches,
    whatsapp_receipts_limit    = EXCLUDED.whatsapp_receipts_limit,
    whatsapp_reminders_limit   = EXCLUDED.whatsapp_reminders_limit,
    sms_limit                  = EXCLUDED.sms_limit,
    google_play_purchase_token = COALESCE(EXCLUDED.google_play_purchase_token, subscriptions.google_play_purchase_token),
    google_play_product_id     = COALESCE(EXCLUDED.google_play_product_id,     subscriptions.google_play_product_id),
    razorpay_sub_id            = COALESCE(EXCLUDED.razorpay_sub_id,            subscriptions.razorpay_sub_id),
    razorpay_payment_id        = COALESCE(EXCLUDED.razorpay_payment_id,        subscriptions.razorpay_payment_id),
    updated_at                 = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

COMMIT;
