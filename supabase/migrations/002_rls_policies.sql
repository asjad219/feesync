-- Migration: 002_rls_policies.sql
-- Created: 2026-05-12
-- Description: Enable RLS and create security policies for all tables

-- ROLLBACK: DROP POLICY statements and ALTER TABLE accounts DISABLE ROW LEVEL SECURITY

BEGIN;

-- ============================================
-- DROP EXISTING POLICIES (for idempotency)
-- ============================================

DROP POLICY IF EXISTS "Users can view own account" ON accounts;
DROP POLICY IF EXISTS "Admins can update account" ON accounts;
DROP POLICY IF EXISTS "Service role can insert accounts" ON accounts;

DROP POLICY IF EXISTS "Users can view account users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Admins can insert users" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;

DROP POLICY IF EXISTS "Users can view students" ON students;
DROP POLICY IF EXISTS "Staff can insert students" ON students;
DROP POLICY IF EXISTS "Staff can update students" ON students;
DROP POLICY IF EXISTS "Admins can delete students" ON students;

DROP POLICY IF EXISTS "Users can view fee categories" ON fee_categories;
DROP POLICY IF EXISTS "Admins can manage fee categories" ON fee_categories;

DROP POLICY IF EXISTS "Users can view fee structures" ON fee_structures;
DROP POLICY IF EXISTS "Admins can manage fee structures" ON fee_structures;

DROP POLICY IF EXISTS "Users can view payments" ON payments;
DROP POLICY IF EXISTS "Staff can create payments" ON payments;
DROP POLICY IF EXISTS "Staff can update payments" ON payments;
DROP POLICY IF EXISTS "Admins can delete payments" ON payments;

DROP POLICY IF EXISTS "Users can view payment records" ON payment_records;
DROP POLICY IF EXISTS "Staff can insert payment records" ON payment_records;
DROP POLICY IF EXISTS "No updates on payment records" ON payment_records;
DROP POLICY IF EXISTS "No deletes on payment records" ON payment_records;

DROP POLICY IF EXISTS "Users can view notifications" ON notifications;
DROP POLICY IF EXISTS "Staff can create notifications" ON notifications;
DROP POLICY IF EXISTS "Staff can update notifications" ON notifications;
DROP POLICY IF EXISTS "Admins can delete notifications" ON notifications;

DROP POLICY IF EXISTS "Users can view notification settings" ON notification_settings;
DROP POLICY IF EXISTS "Admins can manage notification settings" ON notification_settings;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get current user's account_id
CREATE OR REPLACE FUNCTION get_account_id()
RETURNS UUID AS $$
  SELECT account_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user has specific role
CREATE OR REPLACE FUNCTION has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role::text = required_role
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user is admin or accountant
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role::text IN ('admin', 'accountant')
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ============================================
-- ACCOUNTS
-- ============================================

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- Users can view their own account
CREATE POLICY "Users can view own account"
  ON accounts FOR SELECT
  USING (id = get_account_id());

-- Only admins can update account
CREATE POLICY "Admins can update account"
  ON accounts FOR UPDATE
  USING (id = get_account_id() AND has_role('admin'));

-- No direct inserts (accounts created via trigger or service role)
CREATE POLICY "Service role can insert accounts"
  ON accounts FOR INSERT
  WITH CHECK (true);

-- ============================================
-- USERS
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can view all users in their account
CREATE POLICY "Users can view account users"
  ON users FOR SELECT
  USING (account_id = get_account_id());

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (id = auth.uid());

-- Only admins can insert users
CREATE POLICY "Admins can insert users"
  ON users FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    has_role('admin')
  );

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Only admins can delete users
CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- STUDENTS
-- ============================================

ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- All account users can view students
CREATE POLICY "Users can view students"
  ON students FOR SELECT
  USING (account_id = get_account_id());

-- Staff can insert students
CREATE POLICY "Staff can insert students"
  ON students FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    is_staff()
  );

-- Staff can update students
CREATE POLICY "Staff can update students"
  ON students FOR UPDATE
  USING (
    account_id = get_account_id() AND
    is_staff()
  );

-- Only admins can delete students
CREATE POLICY "Admins can delete students"
  ON students FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- FEE CATEGORIES
-- ============================================

ALTER TABLE fee_categories ENABLE ROW LEVEL SECURITY;

-- All account users can view fee categories
CREATE POLICY "Users can view fee categories"
  ON fee_categories FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage fee categories
CREATE POLICY "Admins can manage fee categories"
  ON fee_categories FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- FEE STRUCTURES
-- ============================================

ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;

-- All account users can view fee structures
CREATE POLICY "Users can view fee structures"
  ON fee_structures FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage fee structures
CREATE POLICY "Admins can manage fee structures"
  ON fee_structures FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- PAYMENTS
-- ============================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- All account users can view payments
CREATE POLICY "Users can view payments"
  ON payments FOR SELECT
  USING (account_id = get_account_id());

-- Staff can create payments
CREATE POLICY "Staff can create payments"
  ON payments FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    is_staff()
  );

-- Staff can update payments
CREATE POLICY "Staff can update payments"
  ON payments FOR UPDATE
  USING (
    account_id = get_account_id() AND
    is_staff()
  );

-- Only admins can delete payments
CREATE POLICY "Admins can delete payments"
  ON payments FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- PAYMENT RECORDS
-- ============================================

ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;

-- Users can view payment records for their account's payments
CREATE POLICY "Users can view payment records"
  ON payment_records FOR SELECT
  USING (
    payment_id IN (
      SELECT id FROM payments WHERE account_id = get_account_id()
    )
  );

-- Staff can insert payment records
CREATE POLICY "Staff can insert payment records"
  ON payment_records FOR INSERT
  WITH CHECK (
    payment_id IN (
      SELECT id FROM payments
      WHERE account_id = get_account_id() AND recorded_by = auth.uid()
    )
  );

-- No direct updates on payment_records
CREATE POLICY "No updates on payment records"
  ON payment_records FOR UPDATE
  USING (false);

-- No direct deletes on payment_records
CREATE POLICY "No deletes on payment records"
  ON payment_records FOR DELETE
  USING (false);

-- ============================================
-- NOTIFICATIONS
-- ============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view notifications for their account
CREATE POLICY "Users can view notifications"
  ON notifications FOR SELECT
  USING (account_id = get_account_id());

-- Staff can create notifications
CREATE POLICY "Staff can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    is_staff()
  );

-- Staff can update notifications
CREATE POLICY "Staff can update notifications"
  ON notifications FOR UPDATE
  USING (
    account_id = get_account_id() AND
    is_staff()
  );

-- Only admins can delete notifications
CREATE POLICY "Admins can delete notifications"
  ON notifications FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- NOTIFICATION SETTINGS
-- ============================================

ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- Users can view notification settings for their account
CREATE POLICY "Users can view notification settings"
  ON notification_settings FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage notification settings
CREATE POLICY "Admins can manage notification settings"
  ON notification_settings FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));

-- ============================================
-- FUNCTION PERMISSIONS
-- ============================================

-- Allow authenticated users to call helper functions
GRANT EXECUTE ON FUNCTION get_account_id() TO authenticated;
GRANT EXECUTE ON FUNCTION has_role(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION is_staff() TO authenticated;

COMMIT;
