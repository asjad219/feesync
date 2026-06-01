-- Migration: 007_student_enrollments.sql
-- Description: Support many-to-many relationship between students and batches

BEGIN;

-- Create junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS student_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped')),
  UNIQUE(student_id, batch_id)
);

-- Migrate existing batch_id from students to student_enrollments
INSERT INTO student_enrollments (account_id, student_id, batch_id)
SELECT account_id, id, batch_id
FROM students
WHERE batch_id IS NOT NULL
ON CONFLICT (student_id, batch_id) DO NOTHING;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_student_enrollments_student_id ON student_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_student_enrollments_batch_id ON student_enrollments(batch_id);

-- RLS
ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their enrollments"
  ON student_enrollments FOR SELECT
  USING (account_id = get_account_id());

CREATE POLICY "Staff can manage enrollments"
  ON student_enrollments FOR ALL
  USING (account_id = get_account_id() AND is_staff());

COMMIT;
