-- Migration: 048_add_reminder_days.sql
-- Description: Adds reminder_days_before to app_settings

BEGIN;

ALTER TABLE app_settings
ADD COLUMN IF NOT EXISTS reminder_days_before INTEGER DEFAULT 3;

COMMIT;
