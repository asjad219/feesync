-- Migration: 034_subscription_safety.sql
-- Description: Add unique constraints to subscriptions and update upsert_subscription() to be idempotent and prevent duplicates.

BEGIN;

-- 1. Add unique constraints to prevent duplicate subscription activations across different users
ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS unique_subscriptions_google_play_token;
ALTER TABLE subscriptions ADD CONSTRAINT unique_subscriptions_google_play_token UNIQUE (google_play_purchase_token);

ALTER TABLE subscriptions DROP CONSTRAINT IF EXISTS unique_subscriptions_razorpay_payment_id;
ALTER TABLE subscriptions ADD CONSTRAINT unique_subscriptions_razorpay_payment_id UNIQUE (razorpay_payment_id);

-- 2. Update upsert_subscription function to check for unique token conflicts before inserting
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
  v_limits     JSONB;
  v_row        subscriptions;
  v_existing_id UUID;
BEGIN
  -- 1. Ensure idempotency & safety: Check if Google Play token is already used by another account
  IF p_google_play_token IS NOT NULL THEN
    SELECT id INTO v_existing_id 
    FROM subscriptions 
    WHERE google_play_purchase_token = p_google_play_token AND user_id != p_owner_id;
    
    IF v_existing_id IS NOT NULL THEN
      RAISE EXCEPTION 'Purchase token already used by another user.';
    END IF;
  END IF;

  -- 2. Ensure idempotency & safety: Check if Razorpay payment ID is already used by another account
  IF p_razorpay_payment_id IS NOT NULL THEN
    SELECT id INTO v_existing_id 
    FROM subscriptions 
    WHERE razorpay_payment_id = p_razorpay_payment_id AND user_id != p_owner_id;
    
    IF v_existing_id IS NOT NULL THEN
      RAISE EXCEPTION 'Razorpay payment ID already used by another user.';
    END IF;
  END IF;

  -- 3. Load tier limits
  v_limits := get_plan_limits(p_plan_tier);

  -- 4. Upsert subscription
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
