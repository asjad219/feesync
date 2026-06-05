-- Migration: 014_student_balances_security_invoker.sql
-- Description: Recreate student_balances view with security_invoker enabled to respect RLS policies

BEGIN;

CREATE OR REPLACE VIEW student_balances WITH (security_invoker = true) AS
SELECT
  s.id,
  s.account_id,
  s.admission_number,
  s.roll_number,
  s.first_name,
  s.last_name,
  s.class,
  s.section,
  s.batch_id,
  s.parent_name,
  s.parent_phone,
  s.parent_email,
  s.joining_date,
  s.discount_amount,
  COALESCE(
    (SELECT SUM(fs.amount)
     FROM fee_structures fs
     WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
    0
  ) as total_fee_amount,
  COALESCE(
    (SELECT SUM(amount)
     FROM payments
     WHERE student_id = s.id AND status = 'completed'),
    0
  ) as total_paid_amount,
  (
    COALESCE(
      (SELECT SUM(fs.amount)
       FROM fee_structures fs
       WHERE fs.account_id = s.account_id AND (fs.class = s.class OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id))),
      0
    ) - 
    COALESCE(
      (SELECT SUM(amount)
       FROM payments
       WHERE student_id = s.id AND status = 'completed'),
      0
    )
  ) as balance
FROM students s;

COMMIT;
