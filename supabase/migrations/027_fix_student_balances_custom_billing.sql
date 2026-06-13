-- Migration: 027_fix_student_balances_custom_billing.sql
-- Description: Fix student_balances view to correctly exclude global class-level fee structures when a student's batch has use_global_billing = false.

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
       WHERE fs.account_id = s.account_id AND (
         (fs.class = s.class AND NOT EXISTS (
           SELECT 1 FROM batches b 
           WHERE (b.id = s.batch_id OR b.id IN (
             SELECT batch_id FROM student_enrollments WHERE student_id = s.id AND status = 'active'
           )) AND b.use_global_billing = false
         ))
         OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id)
       )),
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
         WHERE fs.account_id = s.account_id AND (
           (fs.class = s.class AND NOT EXISTS (
             SELECT 1 FROM batches b 
             WHERE (b.id = s.batch_id OR b.id IN (
               SELECT batch_id FROM student_enrollments WHERE student_id = s.id AND status = 'active'
             )) AND b.use_global_billing = false
           ))
           OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id)
         )),
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
         WHERE fs.account_id = s.account_id AND (
           (fs.class = s.class AND NOT EXISTS (
             SELECT 1 FROM batches b 
             WHERE (b.id = s.batch_id OR b.id IN (
               SELECT batch_id FROM student_enrollments WHERE student_id = s.id AND status = 'active'
             )) AND b.use_global_billing = false
           ))
           OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id)
         )),
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
             WHERE fs.account_id = s.account_id AND (
               (fs.class = s.class AND NOT EXISTS (
                 SELECT 1 FROM batches b 
                 WHERE (b.id = s.batch_id OR b.id IN (
                   SELECT batch_id FROM student_enrollments WHERE student_id = s.id AND status = 'active'
                 )) AND b.use_global_billing = false
               ))
               OR fs.id IN (SELECT fee_structure_id FROM fee_assignments WHERE student_id = s.id)
             )),
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
