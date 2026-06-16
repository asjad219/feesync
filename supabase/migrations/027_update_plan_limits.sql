-- Migration: 027_update_plan_limits.sql
-- Created: 2026-06-14
-- Description: Update plan limits to be strict (no unlimited) and backfill existing subscriptions

BEGIN;

-- 1. Update the helper function to return the new strict limits
CREATE OR REPLACE FUNCTION get_plan_limits(p_tier TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT CASE p_tier
    WHEN 'free'      THEN '{"max_students":20,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":2}'::jsonb
    WHEN 'starter'   THEN '{"max_students":200,"max_batches":10,"wa_receipts":2000,"wa_reminders":300,"sms":100,"max_staff":5}'::jsonb
    WHEN 'growth'    THEN '{"max_students":500,"max_batches":50,"wa_receipts":5000,"wa_reminders":1000,"sms":500,"max_staff":10}'::jsonb
    WHEN 'institute' THEN '{"max_students":5000,"max_batches":500,"wa_receipts":50000,"wa_reminders":10000,"sms":1000,"max_staff":50}'::jsonb
    ELSE             '{"max_students":20,"max_batches":2,"wa_receipts":100,"wa_reminders":30,"sms":0,"max_staff":2}'::jsonb
  END;
$$;

-- 2. Backfill existing subscriptions to the new limits
UPDATE subscriptions
SET
  max_students = (get_plan_limits(plan_type)->>'max_students')::integer,
  max_batches = (get_plan_limits(plan_type)->>'max_batches')::integer,
  whatsapp_receipts_limit = (get_plan_limits(plan_type)->>'wa_receipts')::integer,
  whatsapp_reminders_limit = (get_plan_limits(plan_type)->>'wa_reminders')::integer,
  sms_limit = (get_plan_limits(plan_type)->>'sms')::integer,
  max_staff = (get_plan_limits(plan_type)->>'max_staff')::integer;

COMMIT;
