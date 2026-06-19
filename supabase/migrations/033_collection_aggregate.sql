-- Migration: 033_collection_aggregate.sql
-- Description: Create get_total_collection_amount() RPC and add idempotency_key column/unique constraint to payments.

BEGIN;

-- 1. Add idempotency_key to payments to prevent duplicate payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE payments DROP CONSTRAINT IF EXISTS unique_payments_idempotency_key;
ALTER TABLE payments ADD CONSTRAINT unique_payments_idempotency_key UNIQUE (idempotency_key);

-- 2. Create get_total_collection_amount RPC
CREATE OR REPLACE FUNCTION get_total_collection_amount(
  p_account_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  total NUMERIC,
  count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(amount), 0.0) AS total,
    COUNT(id) AS count
  FROM payments
  WHERE account_id = p_account_id
    AND status = 'completed'
    AND (p_start_date IS NULL OR payment_date >= p_start_date::date)
    AND (p_end_date IS NULL OR payment_date <= p_end_date::date);
END;
$$;

COMMIT;
