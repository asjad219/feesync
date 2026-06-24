-- Migration: 039_secure_receipts_storage.sql
-- Description: Secure receipts storage bucket, make it private, enforce tenant isolation.

BEGIN;

-- 1. Make bucket private
UPDATE storage.buckets SET public = false WHERE id = 'receipts';

-- 2. Drop insecure policies
DROP POLICY IF EXISTS "Receipts are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload receipts" ON storage.objects;

-- 3. Create secure policies
CREATE POLICY "Users can view account receipts"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'receipts' AND 
    owner IN (SELECT id FROM users WHERE account_id = get_account_id())
  );

CREATE POLICY "Staff can upload receipts"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts' AND
    auth.role() = 'authenticated' AND
    is_staff()
  );

CREATE POLICY "Staff can update account receipts"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'receipts' AND 
    owner IN (SELECT id FROM users WHERE account_id = get_account_id()) AND
    is_staff()
  );

CREATE POLICY "Staff can delete account receipts"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'receipts' AND 
    owner IN (SELECT id FROM users WHERE account_id = get_account_id()) AND
    is_staff()
  );

COMMIT;
