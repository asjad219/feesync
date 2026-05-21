# FeeSync Lite - Row Level Security Policies

## Overview

All tables use Row Level Security (RLS) for multi-tenancy isolation. Users can only access data belonging to their `account_id`.

---

## Helper Functions

```sql
-- Get current user's account_id
CREATE OR REPLACE FUNCTION get_account_id()
RETURNS UUID AS $$
  SELECT account_id FROM users WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Check if user has specific role
CREATE OR REPLACE FUNCTION has_role(required_role TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() AND role = required_role
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;
```

---

## RLS Policies

### 1. accounts
```sql
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- Users can view their own account
CREATE POLICY "Users can view own account"
  ON accounts FOR SELECT
  USING (id = get_account_id());

-- Only admins can update account
CREATE POLICY "Admins can update account"
  ON accounts FOR UPDATE
  USING (id = get_account_id() AND has_role('admin'));

-- No direct inserts (accounts created via trigger)
CREATE POLICY "No direct inserts on accounts"
  ON accounts FOR INSERT
  WITH CHECK (false);
```

### 2. users
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can view all users in their account
CREATE POLICY "Users can view account users"
  ON users FOR SELECT
  USING (account_id = get_account_id());

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (id = auth.uid());

-- Only admins can insert users
CREATE POLICY "Admins can insert users"
  ON users FOR INSERT
  WITH CHECK (account_id = get_account_id() AND has_role('admin'));

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Only admins can delete users
CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 3. students
```sql
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- All account users can view students
CREATE POLICY "Users can view students"
  ON students FOR SELECT
  USING (account_id = get_account_id());

-- Admins and accountants can insert students
CREATE POLICY "Staff can insert students"
  ON students FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Admins and accountants can update students
CREATE POLICY "Staff can update students"
  ON students FOR UPDATE
  USING (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Only admins can delete students
CREATE POLICY "Admins can delete students"
  ON students FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 4. fee_categories
```sql
ALTER TABLE fee_categories ENABLE ROW LEVEL SECURITY;

-- All account users can view fee categories
CREATE POLICY "Users can view fee categories"
  ON fee_categories FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage fee categories
CREATE POLICY "Admins can manage fee categories"
  ON fee_categories FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 5. fee_structures
```sql
ALTER TABLE fee_structures ENABLE ROW LEVEL SECURITY;

-- All account users can view fee structures
CREATE POLICY "Users can view fee structures"
  ON fee_structures FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage fee structures
CREATE POLICY "Admins can manage fee structures"
  ON fee_structures FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 6. payments
```sql
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- All account users can view payments
CREATE POLICY "Users can view payments"
  ON payments FOR SELECT
  USING (account_id = get_account_id());

-- Only admins and accountants can create payments
CREATE POLICY "Staff can create payments"
  ON payments FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Only admins and accountants can update payments
CREATE POLICY "Staff can update payments"
  ON payments FOR UPDATE
  USING (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Only admins can delete payments
CREATE POLICY "Admins can delete payments"
  ON payments FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 7. payment_records
```sql
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;

-- Users can view payment records for their account's payments
CREATE POLICY "Users can view payment records"
  ON payment_records FOR SELECT
  USING (
    payment_id IN (
      SELECT id FROM payments WHERE account_id = get_account_id()
    )
  );

-- Staff can insert payment records
CREATE POLICY "Staff can insert payment records"
  ON payment_records FOR INSERT
  WITH CHECK (
    payment_id IN (
      SELECT id FROM payments
      WHERE account_id = get_account_id() AND
      (has_role('admin') OR has_role('accountant'))
    )
  );

-- No direct updates on payment_records
CREATE POLICY "No updates on payment records"
  ON payment_records FOR UPDATE
  USING (false);

-- No direct deletes on payment_records
CREATE POLICY "No deletes on payment records"
  ON payment_records FOR DELETE
  USING (false);
```

### 8. notifications
```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view notifications for their account
CREATE POLICY "Users can view notifications"
  ON notifications FOR SELECT
  USING (account_id = get_account_id());

-- Staff can create notifications
CREATE POLICY "Staff can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Staff can update notifications
CREATE POLICY "Staff can update notifications"
  ON notifications FOR UPDATE
  USING (
    account_id = get_account_id() AND
    (has_role('admin') OR has_role('accountant'))
  );

-- Only admins can delete notifications
CREATE POLICY "Admins can delete notifications"
  ON notifications FOR DELETE
  USING (account_id = get_account_id() AND has_role('admin'));
```

### 9. notification_settings
```sql
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- Users can view notification settings for their account
CREATE POLICY "Users can view notification settings"
  ON notification_settings FOR SELECT
  USING (account_id = get_account_id());

-- Only admins can manage notification settings
CREATE POLICY "Admins can manage notification settings"
  ON notification_settings FOR ALL
  USING (account_id = get_account_id() AND has_role('admin'));
```

---

## Service Role Bypass

For administrative operations (e.g., Edge Functions), use the service role key which bypasses RLS.

```typescript
// server.ts - Service role client (for Edge Functions only)
import { createClient } from '@supabase/supabase-js';

export const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } }
);
```

---

## Testing RLS

```sql
-- Test as different user
SET ROLE authenticated;
SET LOCAL request.jwt.claim_sub = '<user-uuid>';

-- Should only see data from own account
SELECT * FROM students;
```

---

## Security Checklist

- [ ] RLS enabled on all tables
- [ ] Service role key never exposed to client
- [ ] All policies tested with different user roles
- [ ] No Bypass RLS on any policy
- [ ] Foreign key constraints enforced
