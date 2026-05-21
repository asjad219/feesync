# FeeSync Lite - Database Schema

## Overview

PostgreSQL schema with Row Level Security (RLS) enabled on all tables. Multi-tenancy via `account_id` column.

---

## Entity Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────────┐
│   accounts  │────▶│   users     │     │  fee_categories │
└─────────────┘     └─────────────┘     └─────────────────┘
       │                   │                    │
       │            ┌──────┴──────┐             │
       │            │             │             │
       ▼            ▼             │             ▼
┌─────────────┐  ┌─────────────┐  │      ┌─────────────────┐
│  students   │◀─┤ fee_structures│─┘      │    payments     │
└─────────────┘  └─────────────┘         └─────────────────┘
       │                                        │
       │                                        │
       ▼                                        ▼
┌─────────────────┐                     ┌─────────────────┐
│notifications   │                     │payment_records  │
└─────────────────┘                     └─────────────────┘
```

---

## Tables

### 1. accounts (Multi-tenancy Root)
```sql
CREATE TABLE accounts (
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
```

### 2. users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'accountant', 'parent', 'student')),
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, email)
);
```

### 3. students
```sql
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  admission_number TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  class TEXT NOT NULL,
  section TEXT,
  stream TEXT,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  date_of_birth DATE,
  parent_name TEXT,
  parent_phone TEXT,
  parent_email TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, admission_number)
);
```

### 4. fee_categories
```sql
CREATE TABLE fee_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(account_id, name)
);
```

### 5. fee_structures
```sql
CREATE TABLE fee_structures (
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
```

### 6. payments
```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  payment_method TEXT CHECK (payment_method IN ('cash', 'bank_transfer', 'mobile_money', 'card', 'other')),
  transaction_id TEXT,
  payment_date DATE NOT NULL,
  recorded_by UUID REFERENCES users(id),
  notes TEXT,
  receipt_number TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 7. payment_records (Junction table for payment-fee relationship)
```sql
CREATE TABLE payment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  fee_structure_id UUID NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 8. notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('payment_reminder', 'payment_confirmation', 'welcome', 'fee_update')),
  channel TEXT NOT NULL CHECK (channel IN ('email', 'sms', 'both')),
  subject TEXT,
  message TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 9. notification_settings
```sql
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  auto_reminder_days INTEGER DEFAULT 7,
  reminder_frequency INTEGER DEFAULT 3,
  enabled_channels TEXT[] DEFAULT ARRAY['email'],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Indexes

```sql
-- Performance indexes
CREATE INDEX idx_students_account_id ON students(account_id);
CREATE INDEX idx_students_class ON students(class);
CREATE INDEX idx_students_admission_number ON students(account_id, admission_number);

CREATE INDEX idx_fee_structures_account_id ON fee_structures(account_id);
CREATE INDEX idx_fee_structures_category ON fee_structures(category_id);
CREATE INDEX idx_fee_structures_class ON fee_structures(class);

CREATE INDEX idx_payments_account_id ON payments(account_id);
CREATE INDEX idx_payments_student_id ON payments(student_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_recorded_by ON payments(recorded_by);

CREATE INDEX idx_notifications_account_id ON notifications(account_id);
CREATE INDEX idx_notifications_student_id ON notifications(student_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for) WHERE status = 'pending';
```

---

## Triggers

### Auto-update updated_at
```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER students_updated_at BEFORE UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER fee_categories_updated_at BEFORE UPDATE ON fee_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER fee_structures_updated_at BEFORE UPDATE ON fee_structures
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## Enums

```sql
-- User roles
CREATE TYPE user_role AS ENUM ('admin', 'accountant', 'parent', 'student');

-- Payment methods
CREATE TYPE payment_method AS ENUM ('cash', 'bank_transfer', 'mobile_money', 'card', 'other');

-- Gender
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');

-- Notification types
CREATE TYPE notification_type AS ENUM ('payment_reminder', 'payment_confirmation', 'welcome', 'fee_update');

-- Notification channels
CREATE TYPE notification_channel AS ENUM ('email', 'sms', 'both');

-- Notification status
CREATE TYPE notification_status AS ENUM ('pending', 'sent', 'failed');
```

---

## Views

### student_balances (Computed view for fee balances)
```sql
CREATE VIEW student_balances AS
SELECT
  s.id,
  s.account_id,
  s.admission_number,
  s.first_name,
  s.last_name,
  s.class,
  COALESCE(SUM(fs.amount), 0) as total_fee_amount,
  COALESCE(SUM(pr.amount), 0) as total_paid_amount,
  COALESCE(SUM(fs.amount), 0) - COALESCE(SUM(pr.amount), 0) as balance
FROM students s
LEFT JOIN fee_structures fs ON fs.account_id = s.account_id AND fs.class = s.class AND fs.is_active = true
LEFT JOIN payment_records pr ON pr.fee_structure_id = fs.id
  AND pr.payment_id IN (SELECT id FROM payments WHERE student_id = s.id AND payments.status = 'completed')
GROUP BY s.id, s.account_id, s.admission_number, s.first_name, s.last_name, s.class;
```
