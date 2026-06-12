-- Migration: 024_update_student_balances_custom_billing.sql
-- Description: Update student_balances view to include custom batch-level billing monthly fees

BEGIN;

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
  s.roll_number,
  s.joining_date,
  s.discount_amount,
  s.gender
FROM students s;

COMMIT;
