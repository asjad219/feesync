-- Migration: 012_message_templates.sql
-- Description: Add editable message template columns to app_settings

ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS tpl_fee_reminder TEXT DEFAULT
    'Hi {parent_name}, a fee of Rs.{amount} is due for {student_name} on {due_date}. Please pay on time to avoid late charges. - {school_name}';

ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS tpl_payment_receipt TEXT DEFAULT
    'Dear {parent_name}, we received Rs.{amount} for {student_name} (Receipt #{receipt_no}). Thank you for your payment. - {school_name}';

ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS tpl_overdue_notice TEXT DEFAULT
    'URGENT: The fee of Rs.{amount} for {student_name} is overdue by {days_overdue} day(s). Please clear dues immediately to avoid penalties. - {school_name}';

ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS tpl_late_fine_applied TEXT DEFAULT
    'Dear {parent_name}, a late fine of Rs.{fine_amount} has been applied to {student_name} account. Total due: Rs.{amount}. - {school_name}';

ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS tpl_new_fee_generated TEXT DEFAULT
    'Dear {parent_name}, a new fee of Rs.{amount} has been generated for {student_name} due on {due_date}. - {school_name}';
