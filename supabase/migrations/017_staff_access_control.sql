-- Migration: 017_staff_access_control.sql
-- Created: 2026-06-08
-- Description: Add permissions and active status to users, and max_staff to subscriptions

BEGIN;

-- 1. Update users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}'::jsonb;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 2. Update subscriptions table
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS max_staff INTEGER DEFAULT 1;

-- 3. Update get_plan_limits function to include max_staff
CREATE OR REPLACE FUNCTION get_plan_limits(p_tier TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT CASE p_tier
    WHEN 'free'      THEN '{"max_students":30,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":1}'::jsonb
    WHEN 'starter'   THEN '{"max_students":200,"max_batches":15,"wa_receipts":-1,"wa_reminders":-1,"sms":100,"max_staff":3}'::jsonb
    WHEN 'growth'    THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":500,"max_staff":-1}'::jsonb
    WHEN 'institute' THEN '{"max_students":-1,"max_batches":-1,"wa_receipts":-1,"wa_reminders":-1,"sms":1000,"max_staff":-1}'::jsonb
    ELSE             '{"max_students":30,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":1}'::jsonb
  END;
$$;

-- 4. Update upsert_subscription function
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
    max_staff,
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
    (v_limits->>'max_staff')::integer,
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
    max_staff                  = EXCLUDED.max_staff,
    google_play_purchase_token = COALESCE(EXCLUDED.google_play_purchase_token, subscriptions.google_play_purchase_token),
    google_play_product_id     = COALESCE(EXCLUDED.google_play_product_id,     subscriptions.google_play_product_id),
    razorpay_sub_id            = COALESCE(EXCLUDED.razorpay_sub_id,            subscriptions.razorpay_sub_id),
    razorpay_payment_id        = COALESCE(EXCLUDED.razorpay_payment_id,        subscriptions.razorpay_payment_id),
    updated_at                 = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

-- 5. Helper Functions for RLS
CREATE OR REPLACE FUNCTION has_permission(required_permission TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() 
      AND is_active = true
      AND (
        role::text = 'admin' -- admins have all permissions implicitly
        OR (permissions->>required_permission)::boolean = true
      )
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Update is_staff to ensure user is active
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() 
      AND is_active = true 
      AND role::text IN ('admin', 'accountant')
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Update get_account_id to ensure user is active
CREATE OR REPLACE FUNCTION get_account_id()
RETURNS UUID AS $$
  SELECT account_id FROM users WHERE id = auth.uid() AND is_active = true;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

COMMIT;
