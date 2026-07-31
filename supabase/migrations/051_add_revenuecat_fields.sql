BEGIN;

ALTER TABLE subscriptions
  ADD COLUMN IF NOT EXISTS revenuecat_entitlement_id TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_customer_id     TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_event_id        TEXT; -- for webhook idempotency

CREATE INDEX IF NOT EXISTS idx_sub_rc_customer_id ON subscriptions(revenuecat_customer_id);
CREATE INDEX IF NOT EXISTS idx_sub_rc_event_id ON subscriptions(revenuecat_event_id);

COMMENT ON COLUMN subscriptions.revenuecat_entitlement_id IS 'Active RC entitlement ID at last webhook event';
COMMENT ON COLUMN subscriptions.revenuecat_customer_id    IS 'RC originalAppUserId (= Supabase user UUID)';
COMMENT ON COLUMN subscriptions.revenuecat_event_id       IS 'Last processed RC webhook event ID for idempotency';

COMMIT;
