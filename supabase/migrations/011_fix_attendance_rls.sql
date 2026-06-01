-- Migration: 011_fix_attendance_rls.sql
-- Description: Refine attendance RLS policies to be more explicit and support upsert

BEGIN;

-- Drop existing imprecise policy
DROP POLICY IF EXISTS "Staff can manage attendance" ON attendance;

-- Explicitly split the "manage" policy into specific actions
-- This ensures that WITH CHECK is correctly applied for INSERT/UPDATE

-- Staff can insert attendance
CREATE POLICY "Staff can insert attendance"
  ON attendance FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    is_staff()
  );

-- Staff can update attendance
CREATE POLICY "Staff can update attendance"
  ON attendance FOR UPDATE
  USING (
    account_id = get_account_id() AND
    is_staff()
  )
  WITH CHECK (
    account_id = get_account_id() AND
    is_staff()
  );

-- Admins can delete attendance
CREATE POLICY "Admins can delete attendance"
  ON attendance FOR DELETE
  USING (
    account_id = get_account_id() AND
    has_role('admin')
  );

COMMIT;
