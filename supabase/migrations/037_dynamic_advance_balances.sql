-- Migration: 037_dynamic_advance_balances.sql
-- Description: Update student_balances to derive advance balances from payments table, and apply advance consumption in generate_recurring_dues using a local tracking temp table.

BEGIN;

DROP VIEW IF EXISTS pending_reminders CASCADE;
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
    (SELECT SUM(p.amount)
     FROM payments p
     WHERE p.student_id = s.id AND p.status = 'completed'),
    0
  ) as total_paid_amount,
  (
    COALESCE((SELECT SUM(d.amount_assigned) FROM dues d WHERE d.student_id = s.id AND d.status != 'cancelled'), 0) -
    COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.student_id = s.id AND p.status = 'completed'), 0)
  ) as balance,
  GREATEST(0, (
    COALESCE((SELECT SUM(d.amount_assigned) FROM dues d WHERE d.student_id = s.id AND d.status != 'cancelled'), 0) -
    COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.student_id = s.id AND p.status = 'completed'), 0)
  )) as due_amount,
  CASE
    WHEN (
      COALESCE((SELECT SUM(d.amount_assigned) FROM dues d WHERE d.student_id = s.id AND d.status != 'cancelled'), 0) -
      COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.student_id = s.id AND p.status = 'completed'), 0)
    ) < 0 THEN 'ADVANCE'
    WHEN (
      COALESCE((SELECT SUM(d.amount_assigned) FROM dues d WHERE d.student_id = s.id AND d.status != 'cancelled'), 0) -
      COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.student_id = s.id AND p.status = 'completed'), 0)
    ) = 0 THEN 'PAID'
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
  s.gender,
  GREATEST(0, (
    COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.student_id = s.id AND p.status = 'completed'), 0) -
    COALESCE((SELECT SUM(d.amount_assigned) FROM dues d WHERE d.student_id = s.id AND d.status != 'cancelled'), 0)
  )) as advance_balance
FROM students s;

-- Recreate pending_reminders
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

CREATE OR REPLACE FUNCTION generate_recurring_dues()
RETURNS void AS $$
DECLARE
  assignment RECORD;
  enrollment RECORD;
  current_period_name TEXT;
  current_due_date DATE;
  existing_due_id UUID;
  current_advance DECIMAL(12, 2);
  current_net_fee DECIMAL(12, 2);
  v_amount_paid DECIMAL(12, 2);
  v_due_amount DECIMAL(12, 2);
  v_status TEXT;
BEGIN
  -- Create a temporary table to track advance balances per student
  CREATE TEMP TABLE temp_student_advances (
    student_id UUID PRIMARY KEY,
    advance_balance DECIMAL(12, 2)
  ) ON COMMIT DROP;

  -- 1. Generate Monthly Dues for Global Fee Assignments
  current_period_name := to_char(CURRENT_DATE, 'Mon YYYY');
  
  FOR assignment IN 
    SELECT fa.*, fs.name as plan_name, fs.amount as base_amount, fs.plan_type, fs.due_date as default_due_day
    FROM fee_assignments fa
    JOIN fee_structures fs ON fa.fee_structure_id = fs.id
    WHERE fa.is_active = true AND fs.plan_type = 'monthly' AND fs.auto_generate_dues = true
  LOOP
    current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date;
    IF assignment.default_due_day IS NOT NULL THEN
      current_due_date := (date_trunc('month', CURRENT_DATE) + (extract(day from assignment.default_due_day) - 1 || ' days')::interval)::date;
    END IF;

    SELECT id INTO existing_due_id 
    FROM dues 
    WHERE student_id = assignment.student_id 
      AND fee_structure_id = assignment.fee_structure_id 
      AND period_name = current_period_name;

    IF existing_due_id IS NULL THEN
      IF NOT EXISTS (SELECT 1 FROM temp_student_advances WHERE student_id = assignment.student_id) THEN
        INSERT INTO temp_student_advances (student_id, advance_balance)
        SELECT 
          assignment.student_id,
          GREATEST(0, 
            COALESCE((SELECT SUM(amount) FROM payments WHERE student_id = assignment.student_id AND status = 'completed'), 0) -
            COALESCE((SELECT SUM(amount_assigned) FROM dues WHERE student_id = assignment.student_id AND status != 'cancelled'), 0)
          );
      END IF;

      SELECT advance_balance INTO current_advance FROM temp_student_advances WHERE student_id = assignment.student_id;
      current_net_fee := assignment.base_amount - assignment.discount_amount;

      IF current_advance >= current_net_fee THEN
        v_amount_paid := current_net_fee;
        v_due_amount := 0;
        v_status := 'paid';
        current_advance := current_advance - current_net_fee;
      ELSIF current_advance > 0 THEN
        v_amount_paid := current_advance;
        v_due_amount := current_net_fee - current_advance;
        v_status := 'pending';
        current_advance := 0;
      ELSE
        v_amount_paid := 0;
        v_due_amount := current_net_fee;
        v_status := 'pending';
      END IF;

      UPDATE temp_student_advances SET advance_balance = current_advance WHERE student_id = assignment.student_id;

      INSERT INTO dues (
        account_id, student_id, fee_structure_id, period_name, due_date,
        amount_assigned, amount_paid, due_amount, status
      ) VALUES (
        assignment.account_id, assignment.student_id, assignment.fee_structure_id, current_period_name, current_due_date,
        current_net_fee, v_amount_paid, v_due_amount, v_status
      );
    END IF;
  END LOOP;

  -- 2. Generate Monthly Dues for Custom Batches
  FOR enrollment IN 
    SELECT se.*, b.monthly_fee as base_amount, b.custom_due_day, b.name as plan_name, s.account_id as student_account_id
    FROM student_enrollments se
    JOIN batches b ON se.batch_id = b.id
    JOIN students s ON se.student_id = s.id
    WHERE se.status = 'active' AND b.use_global_billing = false AND b.custom_auto_due_generation = true
  LOOP
    current_due_date := (date_trunc('month', CURRENT_DATE) + interval '1 month' - interval '1 day')::date;
    IF enrollment.custom_due_day IS NOT NULL THEN
      current_due_date := (date_trunc('month', CURRENT_DATE) + (enrollment.custom_due_day - 1 || ' days')::interval)::date;
    END IF;

    SELECT id INTO existing_due_id 
    FROM dues 
    WHERE student_id = enrollment.student_id 
      AND batch_id = enrollment.batch_id
      AND period_name = 'Batch ' || enrollment.batch_id || ' ' || current_period_name;

    IF existing_due_id IS NULL AND CURRENT_DATE >= current_due_date THEN
      IF NOT EXISTS (SELECT 1 FROM temp_student_advances WHERE student_id = enrollment.student_id) THEN
        INSERT INTO temp_student_advances (student_id, advance_balance)
        SELECT 
          enrollment.student_id,
          GREATEST(0, 
            COALESCE((SELECT SUM(amount) FROM payments WHERE student_id = enrollment.student_id AND status = 'completed'), 0) -
            COALESCE((SELECT SUM(amount_assigned) FROM dues WHERE student_id = enrollment.student_id AND status != 'cancelled'), 0)
          );
      END IF;

      SELECT advance_balance INTO current_advance FROM temp_student_advances WHERE student_id = enrollment.student_id;
      current_net_fee := enrollment.base_amount;

      IF current_advance >= current_net_fee THEN
        v_amount_paid := current_net_fee;
        v_due_amount := 0;
        v_status := 'paid';
        current_advance := current_advance - current_net_fee;
      ELSIF current_advance > 0 THEN
        v_amount_paid := current_advance;
        v_due_amount := current_net_fee - current_advance;
        v_status := 'pending';
        current_advance := 0;
      ELSE
        v_amount_paid := 0;
        v_due_amount := current_net_fee;
        v_status := 'pending';
      END IF;

      UPDATE temp_student_advances SET advance_balance = current_advance WHERE student_id = enrollment.student_id;

      INSERT INTO dues (
        account_id, student_id, batch_id, period_name, due_date,
        amount_assigned, amount_paid, due_amount, status
      ) VALUES (
        enrollment.student_account_id, enrollment.student_id, enrollment.batch_id, 'Batch ' || enrollment.batch_id || ' ' || current_period_name, current_due_date,
        current_net_fee, v_amount_paid, v_due_amount, v_status
      );
    END IF;
  END LOOP;

  -- 3. Apply Late Fines
  UPDATE dues d
  SET 
    status = 'overdue',
    late_fine_applied = late_fine_applied + fs.late_fine,
    due_amount = due_amount + fs.late_fine,
    updated_at = NOW()
  FROM fee_structures fs
  WHERE d.fee_structure_id = fs.id
    AND d.status IN ('pending', 'partial')
    AND d.due_date < (CURRENT_DATE - (fs.grace_days || ' days')::interval)::date
    AND fs.late_fine > 0
    AND d.late_fine_applied = 0;

  -- 4. Simple overdue status update
  UPDATE dues
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE;

  DROP TABLE temp_student_advances;
END;
$$ LANGUAGE plpgsql;

COMMIT;
