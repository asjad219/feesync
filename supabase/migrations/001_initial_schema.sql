-- Migration: 001_initial_schema.sql
-- Created: 2026-05-12
-- Description: Create all core tables, enums, indexes, and triggers

-- ROLLBACK: Run drop statements in reverse order

BEGIN;

-- ============================================
-- ENUMS
-- ============================================

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'accountant', 'parent', 'student');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_method AS ENUM ('cash', 'bank_transfer', 'mobile_money', 'card', 'other');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM ('payment_reminder', 'payment_confirmation', 'welcome', 'fee_update');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_channel AS ENUM ('email', 'sms', 'both');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'failed');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABLES
-- ============================================

-- Accounts (Multi-tenancy Root)
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  school_name TEXT,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'accountant',
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, email)
);

-- Students
CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  admission_number TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  class TEXT NOT NULL,
  section TEXT,
  stream TEXT,
  gender gender_type,
  date_of_birth DATE,
  parent_name TEXT,
  parent_phone TEXT,
  parent_email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, admission_number)
);

-- Fee Categories
CREATE TABLE IF NOT EXISTS fee_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, name)
);

-- Fee Structures
CREATE TABLE IF NOT EXISTS fee_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES fee_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  class TEXT NOT NULL,
  due_date DATE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  payment_method payment_method NOT NULL DEFAULT 'cash',
  transaction_id TEXT,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  recorded_by UUID REFERENCES users(id),
  notes TEXT,
  receipt_number TEXT,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'refunded', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Records (Junction table)
CREATE TABLE IF NOT EXISTS payment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  fee_structure_id UUID NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID REFERENCES students(id) ON DELETE SET NULL,
  type notification_type NOT NULL,
  channel notification_channel NOT NULL DEFAULT 'email',
  subject TEXT,
  message TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  status notification_status DEFAULT 'pending',
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification Settings
CREATE TABLE IF NOT EXISTS notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  auto_reminder_days INTEGER DEFAULT 7,
  reminder_frequency INTEGER DEFAULT 3,
  enabled_channels notification_channel[] DEFAULT ARRAY['email'::notification_channel],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Performance indexes for students
CREATE INDEX IF NOT EXISTS idx_students_account_id ON students(account_id);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class);
CREATE INDEX IF NOT EXISTS idx_students_admission ON students(account_id, admission_number);
CREATE INDEX IF NOT EXISTS idx_students_name ON students(account_id, last_name, first_name);

-- Performance indexes for fee_structures
CREATE INDEX IF NOT EXISTS idx_fee_structures_account_id ON fee_structures(account_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_category ON fee_structures(category_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_class ON fee_structures(class);

-- Performance indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_account_id ON payments(account_id);
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_recorded_by ON payments(recorded_by);

-- Performance indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_account_id ON notifications(account_id);
CREATE INDEX IF NOT EXISTS idx_notifications_student_id ON notifications(student_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_for) WHERE status = 'pending';

-- ============================================
-- TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
DO $$ BEGIN
  CREATE TRIGGER accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER fee_categories_updated_at
    BEFORE UPDATE ON fee_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER fee_structures_updated_at
    BEFORE UPDATE ON fee_structures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- VIEWS
-- ============================================

-- Student balances view
CREATE OR REPLACE VIEW student_balances AS
SELECT
  s.id,
  s.account_id,
  s.admission_number,
  s.first_name,
  s.last_name,
  s.class,
  s.section,
  s.parent_name,
  s.parent_phone,
  s.parent_email,
  COALESCE(
    (SELECT SUM(fs.amount)
     FROM fee_structures fs
     WHERE fs.account_id = s.account_id
       AND fs.class = s.class
       AND fs.is_active = true
    ), 0
  ) as total_fee_amount,
  COALESCE(
    (SELECT SUM(pr.amount)
     FROM payment_records pr
     JOIN payments p ON p.id = pr.payment_id
     WHERE p.student_id = s.id AND p.status = 'completed'
    ), 0
  ) as total_paid_amount,
  COALESCE(
    (SELECT SUM(fs.amount)
     FROM fee_structures fs
     WHERE fs.account_id = s.account_id
       AND fs.class = s.class
       AND fs.is_active = true
    ), 0
  ) - COALESCE(
    (SELECT SUM(pr.amount)
     FROM payment_records pr
     JOIN payments p ON p.id = pr.payment_id
     WHERE p.student_id = s.id AND p.status = 'completed'
    ), 0
  ) as balance
FROM students s;

-- Monthly collection summary
CREATE OR REPLACE VIEW monthly_collections AS
SELECT
  account_id,
  DATE_TRUNC('month', payment_date) as month,
  COUNT(*) as payment_count,
  SUM(amount) as total_collected
FROM payments
WHERE status = 'completed'
GROUP BY account_id, DATE_TRUNC('month', payment_date)
ORDER BY month DESC;

-- Pending reminders view
CREATE OR REPLACE VIEW pending_reminders AS
SELECT
  n.id,
  n.account_id,
  n.student_id,
  n.type,
  n.message,
  n.scheduled_for,
  n.status,
  s.first_name as student_first_name,
  s.last_name as student_last_name,
  s.class,
  s.parent_email,
  s.parent_phone,
  sb.balance
FROM notifications n
JOIN students s ON s.id = n.student_id
JOIN student_balances sb ON sb.id = n.student_id
WHERE n.status = 'pending' AND sb.balance > 0;

COMMIT;
