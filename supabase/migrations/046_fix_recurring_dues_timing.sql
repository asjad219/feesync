-- Migration: 046_fix_recurring_dues_timing.sql
-- Description: Deeply resolve the issue where new students instantly receive overdue bills if enrolled after a custom due date. 
-- 1. trigger_initial_enrollment_due: Always defer to the cron job if a custom due date is set.
-- 2. generate_recurring_dues: Only generate dues if the enrollment/assignment was created ON or BEFORE the due date of that period.

BEGIN;

CREATE OR REPLACE FUNCTION trigger_initial_enrollment_due()
RETURNS TRIGGER AS $$
DECLARE
  b_record RECORD;
  s_record RECORD;
  current_period_name TEXT;
  existing_due_id UUID;
  initial_due_date DATE;
BEGIN
  -- Only trigger when a new active enrollment is created
  IF NEW.status = 'active' THEN
    -- Fetch batch and student info
    SELECT * INTO b_record FROM batches WHERE id = NEW.batch_id;
    SELECT * INTO s_record FROM students WHERE id = NEW.student_id;

    -- Only generate if it's custom billing and auto generation is on
    IF b_record.use_global_billing = false AND b_record.custom_auto_due_generation = true THEN
      
      -- If it's a recurring fee with a custom due day, NEVER generate it immediately.
      -- Let the cron job generate it when the scheduled due date arrives.
      IF b_record.fee_type != 'course_wise' OR b_record.fee_type IS NULL THEN
        IF b_record.custom_due_day IS NOT NULL THEN
          RETURN NEW;
        END IF;
      END IF;

      initial_due_date := CURRENT_DATE;

      -- Determine period name based on fee_type
      IF b_record.fee_type = 'course_wise' THEN
        current_period_name := 'Batch ' || NEW.batch_id || ' Course Fee';
      ELSIF b_record.fee_type = 'quarterly' THEN
        current_period_name := 'Batch ' || NEW.batch_id || ' Q' || extract(quarter from CURRENT_DATE) || ' ' || extract(year from CURRENT_DATE);
      ELSE
        current_period_name := 'Batch ' || NEW.batch_id || ' ' || to_char(CURRENT_DATE, 'Mon YYYY');
      END IF;

      -- Check if due already exists (prevents duplicate if they toggle status)
      SELECT id INTO existing_due_id 
      FROM dues 
      WHERE student_id = NEW.student_id 
        AND batch_id = NEW.batch_id
        AND period_name = current_period_name;

      IF existing_due_id IS NULL THEN
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
          s_record.account_id,
          NEW.student_id,
          NEW.batch_id,
          current_period_name,
          initial_due_date,
          b_record.monthly_fee,
          b_record.monthly_fee,
          'pending'
        );
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update generate_recurring_dues to check created_at against current_due_date
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
      -- Deep Fix: Only generate if today is >= due date AND they were assigned BEFORE/ON the due date.
      IF CURRENT_DATE >= current_due_date AND assignment.created_at::date <= current_due_date THEN
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
      -- Deep Fix: Only generate if today is >= due date AND they were enrolled BEFORE/ON the due date.
      IF CURRENT_DATE >= current_due_date AND enrollment.created_at::date <= current_due_date THEN
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
