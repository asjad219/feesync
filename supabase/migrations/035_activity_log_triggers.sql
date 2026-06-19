-- Migration: 035_activity_log_triggers.sql
-- Description: Auto-generate notifications for events like payment received and student added

BEGIN;

-- Trigger: When a new payment is recorded
CREATE OR REPLACE FUNCTION trigger_payment_notification()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (TG_OP = 'INSERT' OR OLD.status != 'completed') THEN
    INSERT INTO notifications (account_id, student_id, type, channel, subject, message, status, created_at)
    VALUES (
      NEW.account_id,
      NEW.student_id,
      'payment_confirmation',
      'email',
      'Payment Recorded',
      'A payment of ' || NEW.amount || ' has been successfully recorded.',
      'pending',
      NOW()
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_payment_completed ON payments;
CREATE TRIGGER on_payment_completed
  AFTER INSERT OR UPDATE OF status ON payments
  FOR EACH ROW
  EXECUTE FUNCTION trigger_payment_notification();


-- Trigger: When a new student is added
CREATE OR REPLACE FUNCTION trigger_student_welcome_notification()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (account_id, student_id, type, channel, subject, message, status, created_at)
  VALUES (
    NEW.account_id,
    NEW.id,
    'welcome',
    'email',
    'New Student Added',
    NEW.first_name || ' ' || NEW.last_name || ' has been added to the system.',
    'pending',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_student_created ON students;
CREATE TRIGGER on_student_created
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION trigger_student_welcome_notification();

COMMIT;
