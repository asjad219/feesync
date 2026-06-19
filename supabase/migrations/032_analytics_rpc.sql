-- Migration: 032_analytics_rpc.sql
-- Description: Create get_category_collection_distribution() RPC to perform server-side analytics.

BEGIN;

CREATE OR REPLACE FUNCTION get_category_collection_distribution(
  p_account_id UUID
)
RETURNS TABLE (
  category_id UUID,
  category_name TEXT,
  amount NUMERIC,
  percentage NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total NUMERIC;
BEGIN
  -- Get total completed payments amount for the account that are allocated to a fee category
  SELECT COALESCE(SUM(pr.amount), 0.0) INTO v_total
  FROM payment_records pr
  JOIN payments p ON pr.payment_id = p.id
  WHERE p.account_id = p_account_id AND p.status = 'completed';

  RETURN QUERY
  SELECT 
    fc.id AS category_id,
    fc.name AS category_name,
    COALESCE(SUM(pr.amount), 0.0) AS amount,
    CASE 
      WHEN v_total > 0 THEN ROUND(((COALESCE(SUM(pr.amount), 0.0) / v_total) * 100)::numeric, 2)
      ELSE 0.0
    END AS percentage
  FROM fee_categories fc
  JOIN fee_structures fs ON fs.category_id = fc.id
  LEFT JOIN payment_records pr ON pr.fee_structure_id = fs.id
  LEFT JOIN payments p ON pr.payment_id = p.id AND p.status = 'completed'
  WHERE fc.account_id = p_account_id
  GROUP BY fc.id, fc.name
  HAVING COALESCE(SUM(pr.amount), 0.0) > 0
  ORDER BY amount DESC;
END;
$$;

COMMIT;
