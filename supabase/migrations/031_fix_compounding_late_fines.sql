-- Migration: 031_fix_compounding_late_fines.sql
-- Description: Fix generate_recurring_dues() to apply flat late fines only once.

BEGIN;

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
  current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date;

  FOR assignment IN 
    SELECT fa.*, fs.name as plan_name, fs.amount as base_amount, fs.plan_type, fs.due_date as default_due_day
    FROM fee_assignments fa
    JOIN fee_structures fs ON fa.fee_structure_id = fs.id
    WHERE fa.is_active = true AND fs.plan_type = 'monthly' AND fs.auto_generate_dues = true
  LOOP
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

  -- 2. Apply Late Fines and Update Status to Overdue (ONLY if late_fine_applied is 0)
  UPDATE dues d
  SET 
    status = 'overdue',
    late_fine_applied = late_fine_applied + fs.late_fine,
    due_amount = due_amount + fs.late_fine,
    updated_at = NOW()
  FROM fee_structures fs
  WHERE d.fee_structure_id = fs.id
    AND d.status IN ('pending', 'partial') -- ONLY apply penalty when transitioning from pending/partial
    AND d.due_date < (CURRENT_DATE - (fs.grace_days || ' days')::interval)::date
    AND fs.late_fine > 0
    AND d.late_fine_applied = 0; -- Ensures late fine is applied exactly once

  -- 3. Simple overdue status update (even without late fine)
  UPDATE dues
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE;

END;
$$ LANGUAGE plpgsql;

COMMIT;
