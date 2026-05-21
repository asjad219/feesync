-- Migration: 003_phase1_onboarding.sql
-- Created: 2026-05-19
-- Description: Phase 1 onboarding support (account bootstrap, profile fields, deletion requests)

BEGIN;

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS gstin TEXT;

CREATE TABLE IF NOT EXISTS account_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT,
  status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'processing', 'completed', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_account_id
  ON account_deletion_requests(account_id);

CREATE INDEX IF NOT EXISTS idx_account_deletion_requests_user_id
  ON account_deletion_requests(user_id);

ALTER TABLE account_deletion_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own deletion requests" ON account_deletion_requests;
DROP POLICY IF EXISTS "Users can request account deletion" ON account_deletion_requests;

CREATE POLICY "Users can view own deletion requests"
  ON account_deletion_requests FOR SELECT
  USING (account_id = get_account_id());

CREATE POLICY "Users can request account deletion"
  ON account_deletion_requests FOR INSERT
  WITH CHECK (account_id = get_account_id() AND user_id = auth.uid());

CREATE OR REPLACE FUNCTION bootstrap_owner(
  center_name TEXT,
  contact_email TEXT,
  owner_full_name TEXT,
  contact_phone TEXT,
  center_address TEXT,
  center_gstin TEXT,
  center_logo_url TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  existing_account_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT account_id INTO existing_account_id
  FROM users
  WHERE id = auth.uid();

  IF existing_account_id IS NOT NULL THEN
    UPDATE accounts
    SET
      name = COALESCE(center_name, name),
      email = COALESCE(contact_email, email),
      phone = COALESCE(contact_phone, phone),
      address = COALESCE(center_address, address),
      gstin = COALESCE(center_gstin, gstin),
      logo_url = COALESCE(center_logo_url, logo_url)
    WHERE id = existing_account_id;

    UPDATE users
    SET
      email = COALESCE(contact_email, email),
      full_name = COALESCE(owner_full_name, full_name),
      phone = COALESCE(contact_phone, phone)
    WHERE id = auth.uid();

    RETURN existing_account_id;
  END IF;

  INSERT INTO accounts (
    name,
    email,
    phone,
    address,
    gstin,
    logo_url
  ) VALUES (
    center_name,
    contact_email,
    contact_phone,
    center_address,
    center_gstin,
    center_logo_url
  )
  RETURNING id INTO existing_account_id;

  INSERT INTO users (
    id,
    account_id,
    email,
    full_name,
    role,
    phone
  ) VALUES (
    auth.uid(),
    existing_account_id,
    contact_email,
    owner_full_name,
    'admin',
    contact_phone
  );

  RETURN existing_account_id;
END;
$$;

GRANT EXECUTE ON FUNCTION bootstrap_owner(
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT,
  TEXT
) TO authenticated;

COMMIT;
