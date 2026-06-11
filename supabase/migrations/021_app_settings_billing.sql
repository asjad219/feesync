-- Migration: 021_app_settings_billing.sql
-- Description: Add missing billing settings columns for early payment, convenience fees, and taxes to app_settings

BEGIN;

ALTER TABLE app_settings 
ADD COLUMN IF NOT EXISTS early_payment_discount_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS early_payment_discount_percent DECIMAL(5,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS early_payment_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS convenience_fee_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS convenience_fee_percent DECIMAL(5,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS tax_percentage DECIMAL(5,2) DEFAULT 18.0;

COMMIT;
