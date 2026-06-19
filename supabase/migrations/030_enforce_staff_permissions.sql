-- Migration: 030_enforce_staff_permissions.sql
-- Description: Replace generic is_staff() checks with specific has_permission() checks in RLS policies

BEGIN;

-- ============================================
-- DROP EXISTING POLICIES TO REPLACE THEM
-- ============================================

DROP POLICY IF EXISTS "Users can view students" ON students;
DROP POLICY IF EXISTS "Staff can insert students" ON students;
DROP POLICY IF EXISTS "Staff can update students" ON students;

DROP POLICY IF EXISTS "Users can view batches" ON batches;
DROP POLICY IF EXISTS "Staff can manage batches" ON batches;

DROP POLICY IF EXISTS "Users can view attendance" ON attendance;
DROP POLICY IF EXISTS "Staff can insert attendance" ON attendance;
DROP POLICY IF EXISTS "Staff can update attendance" ON attendance;

DROP POLICY IF EXISTS "Users can view payments" ON payments;
DROP POLICY IF EXISTS "Staff can create payments" ON payments;
DROP POLICY IF EXISTS "Staff can update payments" ON payments;

DROP POLICY IF EXISTS "Users can view payment records" ON payment_records;
DROP POLICY IF EXISTS "Staff can insert payment records" ON payment_records;

DROP POLICY IF EXISTS "Users can view notifications" ON notifications;
DROP POLICY IF EXISTS "Staff can create notifications" ON notifications;
DROP POLICY IF EXISTS "Staff can update notifications" ON notifications;

DROP POLICY IF EXISTS "Users can view notification settings" ON notification_settings;
DROP POLICY IF EXISTS "Admins can manage notification settings" ON notification_settings;

-- ============================================
-- STUDENTS
-- ============================================

CREATE POLICY "Users can view students"
  ON students FOR SELECT
  USING (account_id = get_account_id() AND has_permission('view_students'));

CREATE POLICY "Staff can insert students"
  ON students FOR INSERT
  WITH CHECK (account_id = get_account_id() AND has_permission('manage_students'));

CREATE POLICY "Staff can update students"
  ON students FOR UPDATE
  USING (account_id = get_account_id() AND has_permission('manage_students'));

-- ============================================
-- BATCHES
-- ============================================

CREATE POLICY "Users can view batches"
  ON batches FOR SELECT
  USING (account_id = get_account_id() AND has_permission('view_students'));

CREATE POLICY "Staff can manage batches"
  ON batches FOR ALL
  USING (account_id = get_account_id() AND has_permission('manage_students'));

-- ============================================
-- ATTENDANCE
-- ============================================

CREATE POLICY "Users can view attendance"
  ON attendance FOR SELECT
  USING (account_id = get_account_id() AND has_permission('view_students'));

CREATE POLICY "Staff can insert attendance"
  ON attendance FOR INSERT
  WITH CHECK (account_id = get_account_id() AND has_permission('manage_students'));

CREATE POLICY "Staff can update attendance"
  ON attendance FOR UPDATE
  USING (account_id = get_account_id() AND has_permission('manage_students'))
  WITH CHECK (account_id = get_account_id() AND has_permission('manage_students'));

-- ============================================
-- PAYMENTS
-- ============================================

CREATE POLICY "Users can view payments"
  ON payments FOR SELECT
  USING (account_id = get_account_id() AND has_permission('view_payments'));

CREATE POLICY "Staff can create payments"
  ON payments FOR INSERT
  WITH CHECK (account_id = get_account_id() AND has_permission('manage_payments'));

CREATE POLICY "Staff can update payments"
  ON payments FOR UPDATE
  USING (account_id = get_account_id() AND has_permission('manage_payments'));

-- ============================================
-- PAYMENT RECORDS
-- ============================================

CREATE POLICY "Users can view payment records"
  ON payment_records FOR SELECT
  USING (
    payment_id IN (
      SELECT id FROM payments
      WHERE account_id = get_account_id() AND has_permission('view_payments')
    )
  );

CREATE POLICY "Staff can insert payment records"
  ON payment_records FOR INSERT
  WITH CHECK (
    payment_id IN (
      SELECT id FROM payments
      WHERE account_id = get_account_id() AND recorded_by = auth.uid() AND has_permission('manage_payments')
    )
  );

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE POLICY "Users can view notifications"
  ON notifications FOR SELECT
  USING (account_id = get_account_id() AND (has_permission('view_students') OR has_permission('view_payments')));

CREATE POLICY "Staff can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (account_id = get_account_id() AND (has_permission('manage_students') OR has_permission('manage_payments')));

CREATE POLICY "Staff can update notifications"
  ON notifications FOR UPDATE
  USING (account_id = get_account_id() AND (has_permission('manage_students') OR has_permission('manage_payments')));

-- ============================================
-- NOTIFICATION SETTINGS
-- ============================================

CREATE POLICY "Users can view notification settings"
  ON notification_settings FOR SELECT
  USING (account_id = get_account_id() AND has_permission('manage_settings'));

CREATE POLICY "Admins can manage notification settings"
  ON notification_settings FOR ALL
  USING (account_id = get_account_id() AND has_permission('manage_settings'));

COMMIT;
