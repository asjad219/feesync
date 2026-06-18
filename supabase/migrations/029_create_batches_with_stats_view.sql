-- Migration: 029_create_batches_with_stats_view.sql
-- Description: Create a view batches_with_stats that dynamically calculates attendance_percentage, revenue_generated, and pending_dues per batch.

BEGIN;

CREATE OR REPLACE VIEW batches_with_stats WITH (security_invoker = true) AS
SELECT
  id,
  account_id,
  name,
  subject,
  teacher_name,
  status,
  student_count,
  max_capacity,
  monthly_fee,
  color_hex,
  icon_key,
  next_class_time,
  created_at,
  updated_at,
  schedule_days,
  start_time,
  end_time,
  room,
  schedules,
  auto_roll_number,
  collect_parent_details,
  fee_type,
  use_global_billing,
  custom_due_day,
  custom_auto_due_generation,
  COALESCE(
    (
      SELECT SUM(sb.total_paid_amount)
      FROM student_balances sb
      JOIN student_enrollments se ON se.student_id = sb.id AND se.status = 'active'
      WHERE se.batch_id = b.id
    ),
    0.0
  ) as revenue_generated,
  COALESCE(
    (
      SELECT SUM(sb.balance)
      FROM student_balances sb
      JOIN student_enrollments se ON se.student_id = sb.id AND se.status = 'active'
      WHERE se.batch_id = b.id
    ),
    0.0
  ) as pending_dues,
  COALESCE(
    (
      SELECT SUM(CASE WHEN a.status = 'present' THEN 1.0 ELSE 0.0 END) / COUNT(a.id)
      FROM attendance a
      WHERE a.batch_id = b.id
    ),
    0.0
  ) as attendance_percentage
FROM batches b;

COMMIT;
