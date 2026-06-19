-- Migration: 036_scheduled_reminders.sql
-- Description: Add a daily cron job to create scheduled payment reminders for students with pending balances

BEGIN;

-- Enable the pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create a function to generate payment reminders
CREATE OR REPLACE FUNCTION generate_daily_payment_reminders()
RETURNS void AS $$
DECLARE
  reminder_record RECORD;
BEGIN
  -- Find students with pending balances who haven't received a reminder recently
  -- Using student_balances view which has the balance logic
  FOR reminder_record IN 
    SELECT 
      sb.account_id,
      sb.id as student_id,
      sb.balance,
      sb.first_name,
      sb.last_name
    FROM student_balances sb
    WHERE sb.balance > 0
  LOOP
    -- Check if a pending or recent reminder already exists for this student within the last 3 days
    IF NOT EXISTS (
      SELECT 1 FROM notifications 
      WHERE student_id = reminder_record.student_id 
        AND type = 'payment_reminder' 
        AND created_at > NOW() - INTERVAL '3 days'
    ) THEN
      -- Insert a new reminder
      INSERT INTO notifications (
        account_id, 
        student_id, 
        type, 
        channel, 
        subject, 
        message, 
        status, 
        created_at
      )
      VALUES (
        reminder_record.account_id,
        reminder_record.student_id,
        'payment_reminder',
        'email',
        'Fee Payment Reminder',
        'Dear Parent, this is a gentle reminder that a balance of ' || reminder_record.balance || ' is pending for ' || reminder_record.first_name || ' ' || reminder_record.last_name || '.',
        'pending',
        NOW()
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule the job to run every day at 8:00 AM
SELECT cron.schedule(
  'daily-payment-reminders',
  '0 8 * * *', -- Everyday at 08:00
  $$SELECT generate_daily_payment_reminders()$$
);

COMMIT;
