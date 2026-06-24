-- Migration: 041_account_deletion_cron.sql
-- Description: Automated cron job for 30-day soft delete processing.

BEGIN;

CREATE OR REPLACE FUNCTION process_account_deletions()
RETURNS void AS $$
BEGIN
  -- Delete users who requested deletion more than 30 days ago.
  -- Thanks to ON DELETE CASCADE, this will wipe their profile and,
  -- if they are the only user in an account, potentially leave it orphaned
  -- or we can choose to delete the entire account.
  
  DELETE FROM auth.users 
  WHERE id IN (
    SELECT user_id 
    FROM public.account_deletion_requests 
    WHERE status = 'requested' 
      AND created_at < NOW() - INTERVAL '30 days'
  );

  -- We don't need to UPDATE account_deletion_requests because
  -- ON DELETE CASCADE on user_id will automatically remove the request.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attempt to schedule via pg_cron if the extension is installed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    -- Schedule to run daily at midnight
    PERFORM cron.schedule(
      'process_account_deletions_job', 
      '0 0 * * *', 
      'SELECT public.process_account_deletions()'
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- Ignore if cron schema is not accessible or lacks permissions
    NULL;
END $$;

COMMIT;
