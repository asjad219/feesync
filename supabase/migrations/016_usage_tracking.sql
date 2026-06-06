-- Migration: 016_usage_tracking.sql
-- Created: 2026-06-06
-- Description: Track monthly WhatsApp / SMS / AI usage per owner for quota enforcement

BEGIN;

-- ============================================
-- TABLE: subscription_usage
-- ============================================
-- One row per owner per billing period (calendar month).
-- Reset each month by the dues-engine CRON job.

CREATE TABLE IF NOT EXISTS subscription_usage (
  id                          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                    UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period_start                DATE    NOT NULL,   -- First day of billing month, e.g. 2026-06-01
  whatsapp_receipts_used      INTEGER DEFAULT 0,
  whatsapp_reminders_used     INTEGER DEFAULT 0,
  sms_used                    INTEGER DEFAULT 0,
  ai_calls_used               INTEGER DEFAULT 0,
  created_at                  TIMESTAMPTZ DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(owner_id, period_start)
);

-- ============================================
-- TRIGGER: updated_at
-- ============================================
DO $$ BEGIN
  CREATE TRIGGER subscription_usage_updated_at
    BEFORE UPDATE ON subscription_usage
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_sub_usage_owner  ON subscription_usage(owner_id);
CREATE INDEX IF NOT EXISTS idx_sub_usage_period ON subscription_usage(owner_id, period_start);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE subscription_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can view own usage"
  ON subscription_usage FOR SELECT
  USING (owner_id = auth.uid());

-- ============================================
-- HELPER FUNCTION: increment_usage
-- Called each time a WhatsApp/SMS/AI action fires.
-- Uses INSERT ... ON CONFLICT to ensure a row exists for the period.
-- ============================================
CREATE OR REPLACE FUNCTION increment_usage(
  p_owner_id    UUID,
  p_column      TEXT,    -- 'whatsapp_receipts_used' | 'whatsapp_reminders_used' | 'sms_used' | 'ai_calls_used'
  p_increment   INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_period DATE := date_trunc('month', NOW())::date;
BEGIN
  -- Ensure a row exists for this month
  INSERT INTO subscription_usage (owner_id, period_start)
  VALUES (p_owner_id, v_period)
  ON CONFLICT (owner_id, period_start) DO NOTHING;

  -- Increment the specific column dynamically
  EXECUTE format(
    'UPDATE subscription_usage SET %I = %I + $1, updated_at = NOW()
     WHERE owner_id = $2 AND period_start = $3',
    p_column, p_column
  ) USING p_increment, p_owner_id, v_period;
END;
$$;

-- ============================================
-- HELPER FUNCTION: get_current_usage
-- Returns today's usage row for an owner (or zero row if none).
-- ============================================
CREATE OR REPLACE FUNCTION get_current_usage(p_owner_id UUID)
RETURNS subscription_usage
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT *
  FROM   subscription_usage
  WHERE  owner_id     = p_owner_id
    AND  period_start = date_trunc('month', NOW())::date
  LIMIT 1;
$$;

COMMIT;
