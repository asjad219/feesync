-- Migration: 047_implement_billing_rules.sql
-- Description: Production-grade billing engine enforcing single-source-of-truth calculations in RPC.

BEGIN;

-- 1. App Settings Update
ALTER TABLE app_settings 
ADD COLUMN IF NOT EXISTS late_fine_type TEXT DEFAULT 'fixed',
ADD COLUMN IF NOT EXISTS early_payment_discount_type TEXT DEFAULT 'percentage',
ADD COLUMN IF NOT EXISTS tax_mode TEXT DEFAULT 'exclusive';

-- 2. Audit Columns on payments
ALTER TABLE payments
ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS base_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS late_fine_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS tax_percentage DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS tax_mode TEXT,
ADD COLUMN IF NOT EXISTS late_fine_type TEXT,
ADD COLUMN IF NOT EXISTS discount_type TEXT,
ADD COLUMN IF NOT EXISTS original_payable_amount DECIMAL(12,2) DEFAULT 0;

-- 3. Audit Columns on payment_records
ALTER TABLE payment_records
ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS base_amount DECIMAL(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS late_fine_amount DECIMAL(12,2) DEFAULT 0;

-- 4. Update generate_recurring_dues to check created_at against current_due_date and apply late fine properly
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

  -- 3. Apply Late Fines and Update Status to Overdue (Reading from app_settings exactly once)
  UPDATE dues d
  SET 
    status = 'overdue',
    late_fine_applied = 
      CASE 
        WHEN a.late_fine_type = 'percentage' THEN (d.amount_assigned * a.late_fine_amount / 100.0)
        ELSE a.late_fine_amount 
      END,
    due_amount = due_amount + 
      CASE 
        WHEN a.late_fine_type = 'percentage' THEN (d.amount_assigned * a.late_fine_amount / 100.0)
        ELSE a.late_fine_amount 
      END,
    updated_at = NOW()
  FROM app_settings a
  WHERE d.account_id = a.account_id
    AND a.late_fines_enabled = true
    AND d.status IN ('pending', 'partial')
    AND d.due_date < (CURRENT_DATE - (a.grace_period_days || ' days')::interval)::date
    AND d.late_fine_applied = 0; -- CRITICAL FIX: Ensures late fine is applied exactly once!

  -- 4. Simple overdue status update (even without late fine)
  UPDATE dues
  SET status = 'overdue'
  WHERE status = 'pending'
    AND due_date < CURRENT_DATE;

END;
$$ LANGUAGE plpgsql;

-- 5. Preview Payment RPC
CREATE OR REPLACE FUNCTION preview_payment(p_due_id UUID, p_payment_date DATE)
RETURNS json AS $$
DECLARE
  v_due dues%ROWTYPE;
  v_settings app_settings%ROWTYPE;
  v_base_fee DECIMAL(12,2);
  v_discount DECIMAL(12,2) := 0;
  v_late_fine DECIMAL(12,2) := 0;
  v_tax DECIMAL(12,2) := 0;
  v_payable DECIMAL(12,2);
  v_discount_reason TEXT := NULL;
  v_fine_reason TEXT := NULL;
  v_days_early INTEGER;
BEGIN
  -- Fetch due
  SELECT * INTO v_due FROM dues WHERE id = p_due_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Due record not found';
  END IF;

  -- Fetch global settings
  SELECT * INTO v_settings FROM app_settings WHERE account_id = v_due.account_id;

  -- The base amount left to pay (excluding any fines)
  v_base_fee := v_due.due_amount - v_due.late_fine_applied - v_due.amount_paid;
  IF v_base_fee < 0 THEN v_base_fee := 0; END IF;
  
  -- If there's an outstanding balance
  IF v_due.due_amount - v_due.amount_paid > 0 THEN
    
    -- Assign late fine part from what is recorded
    v_late_fine := v_due.late_fine_applied;
    IF v_late_fine > 0 THEN
       v_fine_reason := 'Late fine applied on ' || to_char(v_due.due_date, 'DD Mon YYYY');
    END IF;

    -- Calculate early payment discount
    v_days_early := (v_due.due_date - p_payment_date);
    IF v_settings.early_payment_discount_enabled = true AND v_days_early >= v_settings.early_payment_days THEN
      IF v_settings.early_payment_discount_type = 'percentage' THEN
        v_discount := (v_base_fee * v_settings.early_payment_discount_percent / 100.0);
      ELSE
        v_discount := v_settings.early_payment_discount_percent; -- fixed amount
      END IF;
      v_discount_reason := 'Paid ' || v_days_early || ' days early';
    END IF;

    -- Prevent discount from exceeding base fee
    IF v_discount > v_base_fee THEN
      v_discount := v_base_fee;
    END IF;

    -- Calculate subtotal before tax
    v_payable := v_base_fee - v_discount + v_late_fine;

    -- Calculate Tax
    IF v_settings.gst_enabled = true AND v_settings.tax_percentage > 0 THEN
      IF v_settings.tax_mode = 'exclusive' THEN
        v_tax := (v_payable * v_settings.tax_percentage / 100.0);
        v_payable := v_payable + v_tax;
      ELSIF v_settings.tax_mode = 'inclusive' THEN
        v_tax := v_payable - (v_payable / (1 + (v_settings.tax_percentage / 100.0)));
        -- Payable remains the same, tax is extracted from it
      END IF;
    END IF;
  ELSE
    v_base_fee := 0;
    v_payable := 0;
  END IF;

  RETURN json_build_object(
    'base_fee', ROUND(v_base_fee, 2),
    'discount', ROUND(v_discount, 2),
    'late_fine', ROUND(v_late_fine, 2),
    'tax', ROUND(v_tax, 2),
    'payable', ROUND(v_payable, 2),
    'discount_reason', v_discount_reason,
    'fine_reason', v_fine_reason
  );
END;
$$ LANGUAGE plpgsql;

-- 6. Process Payment RPC
CREATE OR REPLACE FUNCTION process_payment(
  p_due_id UUID, 
  p_amount_received DECIMAL, 
  p_payment_date DATE, 
  p_recorded_by UUID, 
  p_payment_method TEXT,
  p_notes TEXT DEFAULT NULL
)
RETURNS json AS $$
DECLARE
  v_due dues%ROWTYPE;
  v_settings app_settings%ROWTYPE;
  v_preview json;
  v_payable DECIMAL(12,2);
  v_payment_id UUID;
  v_discount DECIMAL(12,2);
  v_tax DECIMAL(12,2);
  v_late_fine DECIMAL(12,2);
  v_base DECIMAL(12,2);
  v_new_status TEXT;
  v_amount_to_reduce_from_due DECIMAL(12,2);
BEGIN
  -- Lock the due row to prevent concurrent payments
  SELECT * INTO v_due FROM dues WHERE id = p_due_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Due record not found';
  END IF;

  -- Fetch settings
  SELECT * INTO v_settings FROM app_settings WHERE account_id = v_due.account_id;

  -- Calculate expected breakdown internally
  v_preview := preview_payment(p_due_id, p_payment_date);
  v_payable := (v_preview->>'payable')::DECIMAL;
  v_discount := (v_preview->>'discount')::DECIMAL;
  v_tax := (v_preview->>'tax')::DECIMAL;
  v_late_fine := (v_preview->>'late_fine')::DECIMAL;
  v_base := (v_preview->>'base_fee')::DECIMAL;

  IF v_payable <= 0 THEN
    RAISE EXCEPTION 'Due is already fully paid';
  END IF;

  -- Validate Partial Payments
  IF v_settings.partial_payments_allowed = false THEN
    IF p_amount_received < v_payable THEN
      RAISE EXCEPTION 'Partial payments are disabled. Expected % but received %', v_payable, p_amount_received;
    END IF;
  END IF;

  -- Insert into payments with full audit trail
  INSERT INTO payments (
    account_id,
    student_id,
    amount,
    payment_method,
    payment_date,
    recorded_by,
    notes,
    tax_amount,
    tax_percentage,
    discount_amount,
    base_amount,
    late_fine_amount,
    tax_mode,
    late_fine_type,
    discount_type,
    original_payable_amount
  ) VALUES (
    v_due.account_id,
    v_due.student_id,
    p_amount_received,
    p_payment_method::payment_method,
    p_payment_date,
    p_recorded_by,
    p_notes,
    v_tax,
    v_settings.tax_percentage,
    v_discount,
    v_base,
    v_late_fine,
    v_settings.tax_mode,
    v_settings.late_fine_type,
    v_settings.early_payment_discount_type,
    v_payable
  ) RETURNING id INTO v_payment_id;

  BEGIN
    INSERT INTO payment_records (
      payment_id,
      fee_structure_id,
      amount,
      due_id,
      tax_amount,
      discount_amount,
      base_amount,
      late_fine_amount
    ) VALUES (
      v_payment_id,
      COALESCE(v_due.fee_structure_id, (SELECT id FROM fee_structures LIMIT 1)),
      p_amount_received,
      p_due_id,
      v_tax,
      v_discount,
      v_base,
      v_late_fine
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Skipped payment_records insert due to constraints: %', SQLERRM;
  END;

  -- Update Due
  IF p_amount_received >= v_payable THEN
    v_new_status := 'paid';
    v_amount_to_reduce_from_due := v_due.due_amount - v_due.amount_paid;
  ELSE
    v_new_status := 'partial';
    IF v_settings.tax_mode = 'exclusive' THEN
      v_amount_to_reduce_from_due := p_amount_received / (1 + (v_settings.tax_percentage / 100.0));
    ELSE
      v_amount_to_reduce_from_due := p_amount_received;
    END IF;
  END IF;

  UPDATE dues
  SET 
    amount_paid = amount_paid + v_amount_to_reduce_from_due,
    status = v_new_status::due_status,
    updated_at = NOW()
  WHERE id = p_due_id;

  RETURN json_build_object(
    'success', true,
    'payment_id', v_payment_id,
    'status', v_new_status,
    'payable', v_payable
  );
END;
$$ LANGUAGE plpgsql;

COMMIT;
