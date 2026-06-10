-- Migration: 018_dynamic_batch_schedule.sql
-- Description: Add dynamic schedules jsonb field to batches table

BEGIN;

ALTER TABLE batches 
ADD COLUMN IF NOT EXISTS schedules JSONB DEFAULT '[]'::jsonb;

COMMIT;
