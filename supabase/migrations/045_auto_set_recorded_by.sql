-- Migration: 045_auto_set_recorded_by.sql
-- Description: Automatically set recorded_by to the current user (auth.uid()) on insert into payments if it is not provided. This prevents RLS violations when staff members record payments without explicitly sending their user ID.

BEGIN;

CREATE OR REPLACE FUNCTION set_payment_recorded_by()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.recorded_by IS NULL THEN
    NEW.recorded_by = auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_payment_insert_set_recorded_by ON payments;
CREATE TRIGGER on_payment_insert_set_recorded_by
  BEFORE INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION set_payment_recorded_by();

-- Also update existing payments that might have NULL recorded_by but were created by the account owner
-- We can't know for sure who created them if they are NULL, but we can set them to the account owner 
-- so that RLS doesn't block updates if needed, though they don't block payment_records anymore since they are already inserted.
-- We'll leave existing NULLs as they are, but this prevents future issues.

COMMIT;
