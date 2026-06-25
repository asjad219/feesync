-- Migration: 042_fix_fee_frequencies.sql
-- Description: Update billing engine to correctly handle monthly, quarterly, and course-wise fee frequencies for custom batches. Added an immediate due generation trigger for new enrollments.

BEGIN;

-- 1. Update generate_recurring_dues to handle different fee frequencies
CREATE OR REPLACE FUNCTION generate_recurring_dues()
RETURNS void AS $$
DECLARE
  assignment RECORD;
  enrollment RECORD;
  current_period_name TEXT;
  current_due_date DATE;
  existing_due_id UUID;
  q_start_date DATE;
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

  -- 2. Generate Dues for Custom Batches (use_global_billing = false) based on fee_type
  FOR enrollment IN 
    SELECT se.*, b.monthly_fee as base_amount, b.custom_due_day, b.name as plan_name, s.account_id as student_account_id, b.fee_type
    FROM student_enrollments se
    JOIN batches b ON se.batch_id = b.id
    JOIN students s ON se.student_id = s.id
    WHERE se.status = 'active' AND b.use_global_billing = false AND b.custom_auto_due_generation = true
  LOOP
    -- Handle Course-Wise (Skip in recurring cron, it's handled by enrollment trigger)
    IF enrollment.fee_type = 'course_wise' THEN
      CONTINUE;
    END IF;

    -- Handle Monthly
    IF enrollment.fee_type = 'monthly' OR enrollment.fee_type IS NULL THEN
      current_period_name := 'Batch ' || enrollment.batch_id || ' ' || to_char(CURRENT_DATE, 'Mon YYYY');
      current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date;
      IF enrollment.custom_due_day IS NOT NULL THEN
        current_due_date := (date_trunc('month', CURRENT_DATE) + (enrollment.custom_due_day - 1 || ' days')::interval)::date;
      END IF;
    END IF;

    -- Handle Quarterly
    IF enrollment.fee_type = 'quarterly' THEN
      current_period_name := 'Batch ' || enrollment.batch_id || ' Q' || extract(quarter from CURRENT_DATE) || ' ' || extract(year from CURRENT_DATE);
      q_start_date := date_trunc('quarter', CURRENT_DATE)::date;
      current_due_date := (q_start_date + interval '3 months' - interval '1 day')::date; -- End of quarter default
      IF enrollment.custom_due_day IS NOT NULL THEN
        current_due_date := (q_start_date + (enrollment.custom_due_day - 1 || ' days')::interval)::date;
      END IF;
    END IF;

    -- Check if due exists for this period
    SELECT id INTO existing_due_id 
    FROM dues 
    WHERE student_id = enrollment.student_id 
      AND batch_id = enrollment.batch_id
      AND period_name = current_period_name;

    -- Generate if it doesn't exist and we've reached the due date
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
          current_period_name,
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

-- 2. Create Trigger Function for Initial Due Generation on Enrollment
CREATE OR REPLACE FUNCTION trigger_initial_enrollment_due()
RETURNS TRIGGER AS $$
DECLARE
  b_record RECORD;
  s_record RECORD;
  current_period_name TEXT;
  existing_due_id UUID;
BEGIN
  -- Only trigger when a new active enrollment is created
  IF NEW.status = 'active' THEN
    -- Fetch batch and student info
    SELECT * INTO b_record FROM batches WHERE id = NEW.batch_id;
    SELECT * INTO s_record FROM students WHERE id = NEW.student_id;

    -- Only generate if it's custom billing and auto generation is on
    IF b_record.use_global_billing = false AND b_record.custom_auto_due_generation = true THEN
      
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
          CURRENT_DATE, -- Initial due is ALWAYS due immediately on enrollment day
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

-- 3. Attach Trigger to student_enrollments
DROP TRIGGER IF EXISTS on_enrollment_create_initial_due ON student_enrollments;
CREATE TRIGGER on_enrollment_create_initial_due
  AFTER INSERT OR UPDATE OF status ON student_enrollments
  FOR EACH ROW
  EXECUTE FUNCTION trigger_initial_enrollment_due();

COMMIT;
