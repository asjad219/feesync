-- Migration: 013_batch_schedule.sql
-- Description: Add schedule fields to batches table

BEGIN;

ALTER TABLE batches 
ADD COLUMN IF NOT EXISTS schedule_days TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS start_time TEXT DEFAULT '16:00',
ADD COLUMN IF NOT EXISTS end_time TEXT DEFAULT '17:30',
ADD COLUMN IF NOT EXISTS room TEXT DEFAULT 'Room 101';

COMMIT;
