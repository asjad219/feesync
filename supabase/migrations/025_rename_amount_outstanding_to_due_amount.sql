-- Migration: 025_rename_amount_outstanding_to_due_amount.sql
-- Created: 2026-06-13
-- Description: Rename amount_outstanding to due_amount in dues table, update dues engine functions, and update student_balances view.

BEGIN;

-- 1. Rename column in dues table
ALTER TABLE dues RENAME COLUMN amount_outstanding TO due_amount;

-- 2. Update generate_recurring_dues function to use new column
CREATE OR REPLACE FUNCTION generate_recurring_dues()
RETURNS void AS $$
DECLARE
  assignment RECORD;
  current_period_name TEXT;
  current_due_date DATE;
  existing_due_id UUID;
BEGIN
  -- 1. Generate Monthly Dues
  current_period_name := to_char(CURRENT_DATE, 'Mon YYYY');
  current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date; -- End of month default or specific day

  FOR assignment IN 
    SELECT fa.*, fs.name as plan_name, fs.amount as base_amount, fs.plan_type, fs.due_date as default_due_day
    FROM fee_assignments fa
    JOIN fee_structures fs ON fa.fee_structure_id = fs.id
    WHERE fa.is_active = true AND fs.plan_type = 'monthly' AND fs.auto_generate_dues = true
  LOOP
    -- Calculate specific due date if default_due_day is provided (assuming it's a day of month)
    -- If default_due_day is a full date in the past, we use the same day in current month
    IF assignment.default_due_day IS NOT NULL THEN
      current_due_date := (date_trunc('month', CURRENT_DATE) + (extract(day from assignment.default_due_day) - 1 || ' days')::interval)::date;
    END IF;

    -- Check if due already exists for this student, plan, and period
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

  -- 2. Apply Late Fines and Update Status to Overdue
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

  -- 3. Simple overdue status update (even without late fine)
  UPDATE dues
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE;

END;
$$ LANGUAGE plpgsql;

-- 3. Update process_due_payment function to use new column and clamp to >= 0
CREATE OR REPLACE FUNCTION process_due_payment(
  p_due_id UUID,
  p_amount DECIMAL
) RETURNS void AS $$
BEGIN
  UPDATE dues
  SET 
    amount_paid = amount_paid + p_amount,
    due_amount = GREATEST(0.0, due_amount - p_amount),
    status = CASE 
      WHEN (due_amount - p_amount) <= 0 THEN 'paid'::due_status
      ELSE 'partial'::due_status
    END,
    updated_at = NOW()
  WHERE id = p_due_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Drop and recreate student_balances view to include due_amount and status columns
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
  (
    COALESCE(
      (SELECT SUM(fs.amount)
       FROM fee_structures fs
       WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
      0
    ) +
    COALESCE(
      (SELECT SUM(b.monthly_fee)
       FROM student_enrollments se
       JOIN batches b ON se.batch_id = b.id
       WHERE se.student_id = s.id AND se.status = 'active' AND b.use_global_billing = false),
      0
    )
  ) as total_fee_amount,
  COALESCE(
    (SELECT SUM(amount)
     FROM payments
     WHERE student_id = s.id AND status = 'completed'),
    0
  ) as total_paid_amount,
  (
    (
      COALESCE(
        (SELECT SUM(fs.amount)
         FROM fee_structures fs
         WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
        0
      ) +
      COALESCE(
        (SELECT SUM(b.monthly_fee)
         FROM student_enrollments se
         JOIN batches b ON se.batch_id = b.id
         WHERE se.student_id = s.id AND se.status = 'active' AND b.use_global_billing = false),
        0
      )
    ) - 
    COALESCE(
      (SELECT SUM(amount)
       FROM payments
       WHERE student_id = s.id AND status = 'completed'),
      0
    )
  ) as balance,
  GREATEST(
    0.0,
    (
      COALESCE(
        (SELECT SUM(fs.amount)
         FROM fee_structures fs
         WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
        0
      ) +
      COALESCE(
        (SELECT SUM(b.monthly_fee)
         FROM student_enrollments se
         JOIN batches b ON se.batch_id = b.id
         WHERE se.student_id = s.id AND se.status = 'active' AND b.use_global_billing = false),
        0
      )
    ) - 
    COALESCE(
      (SELECT SUM(amount)
       FROM payments
       WHERE student_id = s.id AND status = 'completed'),
      0
    ) - 
    s.discount_amount
  ) as due_amount,
  CASE
    WHEN (
      GREATEST(
        0.0,
        (
          COALESCE(
            (SELECT SUM(fs.amount)
             FROM fee_structures fs
             WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
            0
          ) +
          COALESCE(
            (SELECT SUM(b.monthly_fee)
             FROM student_enrollments se
             JOIN batches b ON se.batch_id = b.id
             WHERE se.student_id = s.id AND se.status = 'active' AND b.use_global_billing = false),
            0
          )
        ) - 
        COALESCE(
          (SELECT SUM(amount)
           FROM payments
           WHERE student_id = s.id AND status = 'completed'),
          0
        ) - 
        s.discount_amount
      )
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

COMMIT;
