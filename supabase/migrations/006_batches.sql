-- Migration: 006_batches.sql
-- Created: 2026-05-22
-- Description: Create batches and attendance tables, link students to batches

BEGIN;

-- ============================================
-- NEW TABLES
-- ============================================

-- Batches
CREATE TABLE IF NOT EXISTS batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  teacher_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'upcoming', 'completed')),
  student_count INTEGER DEFAULT 0,
  max_capacity INTEGER NOT NULL,
  monthly_fee DECIMAL(12, 2) NOT NULL,
  color_hex TEXT,
  icon_key TEXT,
  next_class_time TIMESTAMPTZ,
  attendance_percentage DECIMAL(5, 2) DEFAULT 0.0,
  revenue_generated DECIMAL(12, 2) DEFAULT 0.0,
  pending_dues DECIMAL(12, 2) DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, batch_id, date)
);

-- ============================================
-- ALTER EXISTING TABLES
-- ============================================

-- Link students to batches
ALTER TABLE students
ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES batches(id) ON DELETE SET NULL;

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_batches_account_id ON batches(account_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_attendance_account_id ON attendance(account_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_batch_id ON attendance(batch_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_students_batch_id ON students(batch_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Function to handle updated_at (defined in 001_initial_schema.sql)
-- But we ensure it exists or use it safely

DO $$ BEGIN
  CREATE TRIGGER batches_updated_at
    BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TRIGGER attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Automatic student count update for batches
CREATE OR REPLACE FUNCTION update_batch_student_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.batch_id IS NOT NULL THEN
      UPDATE batches SET student_count = student_count + 1 WHERE id = NEW.batch_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.batch_id IS DISTINCT FROM NEW.batch_id THEN
      IF OLD.batch_id IS NOT NULL THEN
        UPDATE batches SET student_count = student_count - 1 WHERE id = OLD.batch_id;
      END IF;
      IF NEW.batch_id IS NOT NULL THEN
        UPDATE batches SET student_count = student_count + 1 WHERE id = NEW.batch_id;
      END IF;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.batch_id IS NOT NULL THEN
      UPDATE batches SET student_count = student_count - 1 WHERE id = OLD.batch_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  CREATE TRIGGER on_student_batch_change
    AFTER INSERT OR UPDATE OR DELETE ON students
    FOR EACH ROW EXECUTE FUNCTION update_batch_student_count();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Batches
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view batches" ON batches;
CREATE POLICY "Users can view batches"
  ON batches FOR SELECT
  USING (account_id = get_account_id());

DROP POLICY IF EXISTS "Staff can manage batches" ON batches;
CREATE POLICY "Staff can manage batches"
  ON batches FOR ALL
  USING (account_id = get_account_id() AND is_staff());

-- Attendance
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view attendance" ON attendance;
CREATE POLICY "Users can view attendance"
  ON attendance FOR SELECT
  USING (account_id = get_account_id());

DROP POLICY IF EXISTS "Staff can manage attendance" ON attendance;
CREATE POLICY "Staff can manage attendance"
  ON attendance FOR ALL
  USING (account_id = get_account_id() AND is_staff());

COMMIT;
