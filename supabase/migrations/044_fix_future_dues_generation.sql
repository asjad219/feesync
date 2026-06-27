-- Migration: 044_fix_future_dues_generation.sql
-- Description: Update trigger_initial_enrollment_due so that if a custom due date is in the future, we skip immediate generation. The cron job (generate_recurring_dues) will generate it when the custom due date arrives. This prevents new students from instantly showing "Dues Remaining" when they enroll before their batch's custom due day.

BEGIN;

CREATE OR REPLACE FUNCTION trigger_initial_enrollment_due()
RETURNS TRIGGER AS $$
DECLARE
  b_record RECORD;
  s_record RECORD;
  current_period_name TEXT;
  existing_due_id UUID;
  initial_due_date DATE;
  q_start_date DATE;
  custom_due_date DATE;
BEGIN
  -- Only trigger when a new active enrollment is created
  IF NEW.status = 'active' THEN
    -- Fetch batch and student info
    SELECT * INTO b_record FROM batches WHERE id = NEW.batch_id;
    SELECT * INTO s_record FROM students WHERE id = NEW.student_id;

    -- Only generate if it's custom billing and auto generation is on
    IF b_record.use_global_billing = false AND b_record.custom_auto_due_generation = true THEN
      
      initial_due_date := CURRENT_DATE;

      -- Determine period name based on fee_type
      IF b_record.fee_type = 'course_wise' THEN
        current_period_name := 'Batch ' || NEW.batch_id || ' Course Fee';
      ELSIF b_record.fee_type = 'quarterly' THEN
        current_period_name := 'Batch ' || NEW.batch_id || ' Q' || extract(quarter from CURRENT_DATE) || ' ' || extract(year from CURRENT_DATE);
        
        IF b_record.custom_due_day IS NOT NULL THEN
          q_start_date := date_trunc('quarter', CURRENT_DATE)::date;
          custom_due_date := (q_start_date + (b_record.custom_due_day - 1 || ' days')::interval)::date;
        ELSE
          custom_due_date := (date_trunc('quarter', CURRENT_DATE) + interval '3 months' - interval '1 day')::date;
        END IF;

      ELSE
        current_period_name := 'Batch ' || NEW.batch_id || ' ' || to_char(CURRENT_DATE, 'Mon YYYY');

        IF b_record.custom_due_day IS NOT NULL THEN
          custom_due_date := (date_trunc('month', CURRENT_DATE) + (b_record.custom_due_day - 1 || ' days')::interval)::date;
        ELSE
          custom_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date;
        END IF;
      END IF;

      -- If the due date is in the future, we skip immediate generation.
      -- The cron job (generate_recurring_dues) will generate it on or after this date.
      -- Exception: course_wise fees are always generated immediately.
      IF b_record.fee_type != 'course_wise' OR b_record.fee_type IS NULL THEN
        IF CURRENT_DATE < custom_due_date THEN
          RETURN NEW;
        END IF;
      END IF;

      -- Set the initial due date (which will be CURRENT_DATE or custom_due_date if we got here)
      IF custom_due_date IS NOT NULL AND CURRENT_DATE < custom_due_date THEN
        initial_due_date := custom_due_date;
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

COMMIT;
