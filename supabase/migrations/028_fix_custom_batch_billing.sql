-- Migration: 028_fix_custom_batch_billing.sql
-- Created: 2026-06-17
-- Description: Update student_balances view to calculate balances purely from the dues table instead of statically adding monthly batch fees. Add batch enrollment support to generate_recurring_dues.

BEGIN;

-- 1. Alter dues table to support custom batches
ALTER TABLE dues
ALTER COLUMN fee_structure_id DROP NOT NULL;

ALTER TABLE dues
ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES batches(id) ON DELETE CASCADE;

-- 2. Alter payment_records to support payments for custom batches
ALTER TABLE payment_records
ALTER COLUMN fee_structure_id DROP NOT NULL;

-- 3. Drop and recreate student_balances view to sum due_amount from dues table
DROP VIEW IF EXISTS student_balances CASCADE;

CREATE OR REPLACE VIEW student_balances WITH (security_invoker = true) AS
SELECT
  s.id,
  s.account_id,
  s.admission_number,
  s.first_name,
  s.last_name,
  s.class,
  s.section,
  s.batch_id,
  s.parent_name,
  s.parent_phone,
  s.parent_email,
  COALESCE(
    (SELECT SUM(d.amount_assigned)
     FROM dues d
     WHERE d.student_id = s.id AND d.status != 'cancelled'),
    0
  ) as total_fee_amount,
  COALESCE(
    (SELECT SUM(d.amount_paid)
     FROM dues d
     WHERE d.student_id = s.id AND d.status != 'cancelled'),
    0
  ) as total_paid_amount,
  COALESCE(
    (SELECT SUM(d.due_amount)
     FROM dues d
     WHERE d.student_id = s.id AND d.status != 'cancelled'),
    0
  ) as balance,
  COALESCE(
    (SELECT SUM(d.due_amount)
     FROM dues d
     WHERE d.student_id = s.id AND d.status != 'cancelled' AND d.due_amount > 0),
    0
  ) as due_amount,
  CASE
    WHEN COALESCE(
      (SELECT SUM(d.due_amount)
       FROM dues d
       WHERE d.student_id = s.id AND d.status != 'cancelled' AND d.due_amount > 0),
      0
    ) <= 0 THEN 'PAID'
    WHEN EXISTS (
      SELECT 1 FROM dues d
      WHERE d.student_id = s.id
        AND d.due_date < CURRENT_DATE
        AND d.due_amount > 0
        AND d.status NOT IN ('paid', 'cancelled')
    ) THEN 'OVERDUE'
    ELSE 'DUE'
  END as status,
  s.roll_number,
  s.joining_date,
  s.discount_amount,
  s.gender
FROM students s;

-- 4. Recreate pending_reminders view since it depended on student_balances
CREATE OR REPLACE VIEW pending_reminders AS
SELECT
  n.id,
  n.account_id,
  n.student_id,
  n.type,
  n.message,
  n.scheduled_for,
  n.status,
  s.first_name as student_first_name,
  s.last_name as student_last_name,
  s.class,
  s.parent_email,
  s.parent_phone,
  sb.balance
FROM notifications n
JOIN students s ON s.id = n.student_id
JOIN student_balances sb ON sb.id = n.student_id
WHERE n.status = 'pending' AND sb.balance > 0;

-- 5. Update generate_recurring_dues to also generate dues for custom batches
CREATE OR REPLACE FUNCTION generate_recurring_dues()
RETURNS void AS $$
DECLARE
  assignment RECORD;
  enrollment RECORD;
  current_period_name TEXT;
  current_due_date DATE;
  existing_due_id UUID;
BEGIN
  -- 1. Generate Monthly Dues for Global Fee Assignments
  current_period_name := to_char(CURRENT_DATE, 'Mon YYYY');
  
  FOR assignment IN 
    SELECT fa.*, fs.name as plan_name, fs.amount as base_amount, fs.plan_type, fs.due_date as default_due_day
    FROM fee_assignments fa
    JOIN fee_structures fs ON fa.fee_structure_id = fs.id
    WHERE fa.is_active = true AND fs.plan_type = 'monthly' AND fs.auto_generate_dues = true
  LOOP
    current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date; -- End of month default
    IF assignment.default_due_day IS NOT NULL THEN
      current_due_date := (date_trunc('month', CURRENT_DATE) + (extract(day from assignment.default_due_day) - 1 || ' days')::interval)::date;
    END IF;

    SELECT id INTO existing_due_id 
    FROM dues 
    WHERE student_id = assignment.student_id 
      AND fee_structure_id = assignment.fee_structure_id 
      AND period_name = current_period_name;

    IF existing_due_id IS NULL THEN
      INSERT INTO dues (
        account_id,
        student_id,
        fee_structure_id,
        period_name,
        due_date,
        amount_assigned,
        due_amount,
        status
      ) VALUES (
        assignment.account_id,
        assignment.student_id,
        assignment.fee_structure_id,
        current_period_name,
        current_due_date,
        assignment.base_amount - assignment.discount_amount,
        assignment.base_amount - assignment.discount_amount,
        'pending'
      );
    END IF;
  END LOOP;

  -- 2. Generate Monthly Dues for Custom Batches (use_global_billing = false)
  FOR enrollment IN 
    SELECT se.*, b.monthly_fee as base_amount, b.custom_due_day, b.name as plan_name, s.account_id as student_account_id
    FROM student_enrollments se
    JOIN batches b ON se.batch_id = b.id
    JOIN students s ON se.student_id = s.id
    WHERE se.status = 'active' AND b.use_global_billing = false AND b.custom_auto_due_generation = true
  LOOP
    current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date; -- End of month default
    IF enrollment.custom_due_day IS NOT NULL THEN
      current_due_date := (date_trunc('month', CURRENT_DATE) + (enrollment.custom_due_day - 1 || ' days')::interval)::date;
    END IF;

    SELECT id INTO existing_due_id 
    FROM dues 
    WHERE student_id = enrollment.student_id 
      AND batch_id = enrollment.batch_id
      AND period_name = 'Batch ' || enrollment.batch_id || ' ' || current_period_name;

    IF existing_due_id IS NULL THEN
      IF CURRENT_DATE >= current_due_date THEN
        INSERT INTO dues (
          account_id,
          student_id,
          batch_id,
          period_name,
          due_date,
          amount_assigned,
          due_amount,
          status
        ) VALUES (
          enrollment.student_account_id,
          enrollment.student_id,
          enrollment.batch_id,
          'Batch ' || enrollment.batch_id || ' ' || current_period_name,
          current_due_date,
          enrollment.base_amount,
          enrollment.base_amount,
          'pending'
        );
      END IF;
    END IF;
  END LOOP;

  -- 3. Apply Late Fines and Update Status to Overdue
  UPDATE dues d
  SET 
    status = 'overdue',
    late_fine_applied = late_fine_applied + fs.late_fine,
    due_amount = due_amount + fs.late_fine,
    updated_at = NOW()
  FROM fee_structures fs
  WHERE d.fee_structure_id = fs.id
    AND d.status IN ('pending', 'partial', 'overdue')
    AND d.due_date < (CURRENT_DATE - (fs.grace_days || ' days')::interval)::date
    AND fs.late_fine > 0;

  -- 4. Simple overdue status update (even without late fine)
  UPDATE dues
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE;

END;
$$ LANGUAGE plpgsql;

COMMIT;
