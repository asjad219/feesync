-- Migration: 049_fix_unlimited_quota_sentinels.sql
-- Created: 2026-07-11
-- Description: Fix any subscription rows that still have -1 as plan limits.
--   Migration 027 was intended to backfill all rows to finite limits, but rows
--   created before that migration or with -1 explicitly set (e.g., trial rows)
--   may still have -1 sentinel values.
--   
--   This migration replaces all -1 sentinel values with the correct plan limits
--   from get_plan_limits(), so the DB is consistent. The Flutter client already
--   handles -1 correctly (treats it as unlimited), but this ensures future
--   queries are clean and analytics are accurate.

BEGIN;

-- 1. Backfill any remaining rows with -1 values to real plan limits.
--    Only update columns that have -1 (to avoid overwriting legitimate 0s).
UPDATE subscriptions
SET
  max_students = CASE
    WHEN max_students < 0 THEN (get_plan_limits(plan_type)->>'max_students')::integer
    ELSE max_students
  END,
  max_batches = CASE
    WHEN max_batches < 0 THEN (get_plan_limits(plan_type)->>'max_batches')::integer
    ELSE max_batches
  END,
  whatsapp_receipts_limit = CASE
    WHEN whatsapp_receipts_limit < 0 THEN (get_plan_limits(plan_type)->>'wa_receipts')::integer
    ELSE whatsapp_receipts_limit
  END,
  whatsapp_reminders_limit = CASE
    WHEN whatsapp_reminders_limit < 0 THEN (get_plan_limits(plan_type)->>'wa_reminders')::integer
    ELSE whatsapp_reminders_limit
  END,
  sms_limit = CASE
    WHEN sms_limit < 0 THEN (get_plan_limits(plan_type)->>'sms')::integer
    ELSE sms_limit
  END,
  max_staff = CASE
    WHEN max_staff < 0 THEN (get_plan_limits(plan_type)->>'max_staff')::integer
    ELSE max_staff
  END,
  updated_at = NOW()
WHERE
  max_students < 0
  OR max_batches < 0
  OR whatsapp_receipts_limit < 0
  OR whatsapp_reminders_limit < 0
  OR sms_limit < 0
  OR max_staff < 0;

-- 2. Add a CHECK constraint so -1 is never written again for active subscriptions.
--    This enforces data integrity going forward. The constraint allows NULL
--    to handle any optional fields in the future.
ALTER TABLE subscriptions
  DROP CONSTRAINT IF EXISTS chk_no_negative_limits;

ALTER TABLE subscriptions
  ADD CONSTRAINT chk_no_negative_limits CHECK (
    (max_students   IS NULL OR max_students   >= 0) AND
    (max_batches    IS NULL OR max_batches    >= 0) AND
    (max_staff      IS NULL OR max_staff      >= 0) AND
    (whatsapp_receipts_limit  IS NULL OR whatsapp_receipts_limit  >= 0) AND
    (whatsapp_reminders_limit IS NULL OR whatsapp_reminders_limit >= 0) AND
    (sms_limit      IS NULL OR sms_limit      >= 0)
  );

COMMIT;
