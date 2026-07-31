BEGIN;

-- Lock down: revoke direct RPC access from authenticated clients
REVOKE EXECUTE ON FUNCTION upsert_subscription FROM authenticated;
REVOKE EXECUTE ON FUNCTION upsert_subscription FROM anon;

-- Replace permissive UPDATE policy with a restricted one:
-- Clients may only update their own row when staying on free plan
DROP POLICY IF EXISTS "Owner can update own subscription" ON subscriptions;
CREATE POLICY "Owner can only maintain free subscription"
  ON subscriptions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (plan_type = 'free');

-- Client can still INSERT their own free-tier row (new user creation)
-- The existing INSERT policy is correct, no change needed.

COMMIT;
