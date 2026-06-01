-- Migration: 008_student_enhancements.sql
-- Description: Add roll number, joining date, and discount to students

BEGIN;

ALTER TABLE students 
ADD COLUMN IF NOT EXISTS roll_number TEXT,
ADD COLUMN IF NOT EXISTS joining_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(10, 2) DEFAULT 0;

-- Update student_balances view to include new fields if needed, 
-- but student_balances is likely a view on payments/fees. 
-- Let's check if we need to refresh or recreate it.
-- For now, just adding columns to the base table.

COMMIT;
