-- Migration: 019_batch_settings.sql
-- Description: Add auto_roll_number and collect_parent_details fields to batches table

BEGIN;

ALTER TABLE batches 
ADD COLUMN IF NOT EXISTS auto_roll_number BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS collect_parent_details BOOLEAN DEFAULT true;

COMMIT;
