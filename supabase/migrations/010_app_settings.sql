-- Migration: 010_app_settings.sql
-- Description: Comprehensive settings table for operational control center

BEGIN;

CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Center Settings
  center_name TEXT,
  center_address TEXT,
  center_phone TEXT,
  center_email TEXT,
  center_website TEXT,
  gstin TEXT,
  academic_year TEXT DEFAULT '2024-25',
  currency TEXT DEFAULT 'INR',
  timezone TEXT DEFAULT 'IST',
  
  -- Operational Toggles
  gst_enabled BOOLEAN DEFAULT true,
  qr_verification_enabled BOOLEAN DEFAULT true,
  parent_portal_enabled BOOLEAN DEFAULT true,
  digital_signature_enabled BOOLEAN DEFAULT false,
  
  -- Fee Engine Settings
  default_due_day INTEGER DEFAULT 5,
  auto_due_generation BOOLEAN DEFAULT true,
  late_fines_enabled BOOLEAN DEFAULT true,
  late_fine_amount DECIMAL(12, 2) DEFAULT 100,
  grace_period_days INTEGER DEFAULT 3,
  partial_payments_allowed BOOLEAN DEFAULT true,
  
  -- AI & Automation
  ai_reminders_enabled BOOLEAN DEFAULT true,
  ai_predictions_enabled BOOLEAN DEFAULT true,
  ocr_enabled BOOLEAN DEFAULT true,
  
  -- Notification Settings (Merged from old table if needed)
  whatsapp_enabled BOOLEAN DEFAULT true,
  sms_fallback_enabled BOOLEAN DEFAULT true,
  auto_receipt_enabled BOOLEAN DEFAULT true,
  
  -- UI Customization
  theme_mode TEXT DEFAULT 'dark_luxury',
  dashboard_layout TEXT DEFAULT 'bento',
  glass_effects_enabled BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own account settings"
  ON app_settings FOR SELECT
  USING (account_id IN (SELECT account_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Admins can update their own account settings"
  ON app_settings FOR UPDATE
  USING (account_id IN (SELECT account_id FROM users WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins can insert their own account settings"
  ON app_settings FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM users WHERE id = auth.uid() AND role = 'admin'));

COMMIT;
