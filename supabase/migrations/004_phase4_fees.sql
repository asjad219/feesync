-- Migration: 004_phase4_fees.sql
-- Created: 2026-05-20
-- Description: Advanced fee management features: recurring plans, assignments, and dues engine

BEGIN;

-- ============================================
-- ENUMS
-- ============================================

DO $$ BEGIN
  CREATE TYPE fee_plan_type AS ENUM (
    'monthly',
    'quarterly',
    'half_yearly',
    'annual',
    'custom',
    'per_class'
  );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE due_status AS ENUM (
    'pending',
    'partial',
    'paid',
    'overdue',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- ALTER EXISTING TABLES
-- ============================================

-- Enhance fee_structures for recurring logic
ALTER TABLE fee_structures
ADD COLUMN IF NOT EXISTS plan_type fee_plan_type DEFAULT 'monthly',
ADD COLUMN IF NOT EXISTS late_fine DECIMAL(12, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS grace_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gst_percent DECIMAL(5, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS auto_generate_dues BOOLEAN DEFAULT true;

-- ============================================
-- NEW TABLES
-- ============================================

-- Fee Assignments: Links students to fee plans
CREATE TABLE IF NOT EXISTS fee_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  fee_structure_id UUID NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  discount_amount DECIMAL(12, 2) DEFAULT 0,
  waiver_reason TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, fee_structure_id)
);

-- Dues: Specific billing records generated from assignments
CREATE TABLE IF NOT EXISTS dues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  fee_structure_id UUID NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
  period_name TEXT NOT NULL, -- e.g., "April 2026"
  due_date DATE NOT NULL,
  amount_assigned DECIMAL(12, 2) NOT NULL,
  amount_paid DECIMAL(12, 2) DEFAULT 0,
  amount_outstanding DECIMAL(12, 2) NOT NULL,
  late_fine_applied DECIMAL(12, 2) DEFAULT 0,
  status due_status DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Link payment records to specific dues
ALTER TABLE payment_records
ADD COLUMN IF NOT EXISTS due_id UUID REFERENCES dues(id) ON DELETE SET NULL;

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_fee_assignments_student ON fee_assignments(student_id);
CREATE INDEX IF NOT EXISTS idx_fee_assignments_account ON fee_assignments(account_id);
CREATE INDEX IF NOT EXISTS idx_dues_student ON dues(student_id);
CREATE INDEX IF NOT EXISTS idx_dues_account ON dues(account_id);
CREATE INDEX IF NOT EXISTS idx_dues_status ON dues(status);
CREATE INDEX IF NOT EXISTS idx_dues_date ON dues(due_date);

-- ============================================
-- TRIGGERS
-- ============================================

CREATE TRIGGER fee_assignments_updated_at BEFORE UPDATE ON fee_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER dues_updated_at BEFORE UPDATE ON dues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- RLS POLICIES
-- ============================================

-- Fee Assignments
ALTER TABLE fee_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view fee assignments"
  ON fee_assignments FOR SELECT
  USING (account_id = get_account_id());

CREATE POLICY "Admins can manage fee assignments"
  ON fee_assignments FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));

-- Dues
ALTER TABLE dues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view dues"
  ON dues FOR SELECT
  USING (account_id = get_account_id());

CREATE POLICY "Staff can manage dues"
  ON dues FOR ALL
  USING (account_id = get_account_id() AND is_staff());

COMMIT;
