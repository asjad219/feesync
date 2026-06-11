-- Migration: 020_batch_billing_settings.sql
-- Description: Add custom fee frequency and billing rollover settings per batch

BEGIN;

ALTER TABLE batches 
ADD COLUMN IF NOT EXISTS fee_type VARCHAR(20) DEFAULT 'monthly',
ADD COLUMN IF NOT EXISTS use_global_billing BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS custom_due_day INTEGER,
ADD COLUMN IF NOT EXISTS custom_auto_due_generation BOOLEAN;

COMMIT;
