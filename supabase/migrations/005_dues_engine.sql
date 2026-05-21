-- Migration: 005_dues_engine.sql
-- Created: 2026-05-20
-- Description: Automated dues generation engine and late fine logic

BEGIN;

-- ============================================
-- CORE ENGINE FUNCTION
-- ============================================

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
        amount_outstanding,
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
    amount_outstanding = amount_outstanding + fs.late_fine,
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

-- ============================================
-- HELPER: Process Payment
-- ============================================

-- Function to handle payment recording and updating dues
CREATE OR REPLACE FUNCTION process_due_payment(
  p_due_id UUID,
  p_amount DECIMAL
) RETURNS void AS $$
BEGIN
  UPDATE dues
  SET 
    amount_paid = amount_paid + p_amount,
    amount_outstanding = amount_outstanding - p_amount,
    status = CASE 
      WHEN (amount_outstanding - p_amount) <= 0 THEN 'paid'::due_status
      ELSE 'partial'::due_status
    END,
    updated_at = NOW()
  WHERE id = p_due_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- AUTOMATIC DUE UPDATE TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION handle_payment_record_insert()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.due_id IS NOT NULL THEN
    PERFORM process_due_payment(NEW.due_id, NEW.amount);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_payment_record_insert
  AFTER INSERT ON payment_records
  FOR EACH ROW
  EXECUTE FUNCTION handle_payment_record_insert();

COMMIT;
