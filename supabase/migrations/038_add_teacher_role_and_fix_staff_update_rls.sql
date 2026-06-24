-- Migration: 038_add_teacher_role_and_fix_staff_update_rls.sql
-- Description: Add teacher value to user_role enum, update is_staff and has_permission helper functions, add RLS policy for admins to update users, and implement triggers for self-lockout prevention, privilege escalation prevention, and audit logging.

-- 1. Safely add 'teacher' to user_role enum
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'teacher'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'teacher';
  END IF;
END
$$;

-- 2. Create Staff Audit Logs table
CREATE TABLE IF NOT EXISTS staff_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID,
  target_user_id UUID,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  old_value JSONB,
  new_value JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on audit logs
ALTER TABLE staff_audit_logs ENABLE ROW LEVEL SECURITY;

-- Admins can view audit logs of their own account
DROP POLICY IF EXISTS "Admins can view audit logs" ON staff_audit_logs;
CREATE POLICY "Admins can view audit logs"
  ON staff_audit_logs FOR SELECT
  USING (account_id = get_account_id() AND has_role('admin'));

-- 3. Update is_staff() helper function to include 'teacher'
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid() 
      AND is_active = true 
      AND role::text IN ('admin', 'accountant', 'teacher')
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- 4. Update has_permission() helper function to support role-based resolution & fallback
CREATE OR REPLACE FUNCTION has_permission(required_permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_role TEXT;
  v_permissions JSONB;
BEGIN
  -- Query the user's role and custom permissions
  SELECT role::text, permissions
  INTO v_role, v_permissions
  FROM users
  WHERE id = auth.uid() AND is_active = true;

  -- If user not found, return false
  IF v_role IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Admin always has full access
  IF v_role = 'admin' THEN
    RETURN TRUE;
  END IF;

  -- Check explicit permission in the JSON field if set
  IF (v_permissions->>required_permission)::boolean = TRUE THEN
    RETURN TRUE;
  END IF;
  IF (v_permissions->>required_permission)::boolean = FALSE THEN
    RETURN FALSE;
  END IF;

  -- Fall back to default role-based permissions
  IF v_role = 'teacher' THEN
    RETURN required_permission IN ('view_students', 'manage_students');
  ELSIF v_role = 'accountant' THEN
    RETURN required_permission IN ('view_students', 'view_payments', 'manage_payments', 'view_reports');
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 5. Recreate users update policies with WITH CHECK clause for tenant validation
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can update users" ON users;

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

CREATE POLICY "Admins can update users"
  ON users FOR UPDATE
  USING (account_id = get_account_id() AND has_role('admin'))
  WITH CHECK (account_id = get_account_id());

-- 6. BEFORE UPDATE validation trigger (prevents self-lockout and privilege escalation)
CREATE OR REPLACE FUNCTION validate_user_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent deactivating/downgrading the last admin in the account
  IF OLD.role = 'admin' AND (NEW.role IS DISTINCT FROM 'admin' OR NEW.is_active = false) THEN
    IF NOT EXISTS (
      SELECT 1 FROM users
      WHERE account_id = OLD.account_id
        AND id IS DISTINCT FROM OLD.id
        AND role = 'admin'
        AND is_active = true
    ) THEN
      RAISE EXCEPTION 'Cannot deactivate or downgrade the last active admin in the account.';
    END IF;
  END IF;

  -- Non-admins cannot elevate privileges (cannot modify roles, permissions, or account_id)
  IF NOT has_role('admin') THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Only admins can modify roles.';
    END IF;
    IF NEW.permissions IS DISTINCT FROM OLD.permissions THEN
      RAISE EXCEPTION 'Only admins can modify permissions.';
    END IF;
    IF NEW.account_id IS DISTINCT FROM OLD.account_id THEN
      RAISE EXCEPTION 'Cannot modify account association.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS users_validation_trigger ON users;
CREATE TRIGGER users_validation_trigger
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION validate_user_update();

-- 7. AFTER INSERT/UPDATE trigger for audit logging
CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
DECLARE
  v_actor_id UUID;
  v_action TEXT;
  v_old JSONB := NULL;
  v_new JSONB := NULL;
BEGIN
  v_actor_id := auth.uid();

  IF TG_OP = 'INSERT' THEN
    v_action := 'invite_staff';
    v_new := jsonb_build_object(
      'role', NEW.role,
      'permissions', NEW.permissions,
      'is_active', NEW.is_active
    );
    
    INSERT INTO staff_audit_logs (actor_user_id, target_user_id, account_id, action_type, new_value)
    VALUES (v_actor_id, NEW.id, NEW.account_id, v_action, v_new);

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.is_active = true AND NEW.is_active = false THEN
      v_action := 'deactivate_staff';
    ELSIF OLD.is_active = false AND NEW.is_active = true THEN
      v_action := 'activate_staff';
    ELSIF OLD.role IS DISTINCT FROM NEW.role THEN
      v_action := 'role_change';
    ELSIF OLD.permissions IS DISTINCT FROM NEW.permissions THEN
      v_action := 'permission_update';
    ELSE
      v_action := 'update_staff';
    END IF;

    v_old := jsonb_build_object(
      'role', OLD.role,
      'permissions', OLD.permissions,
      'is_active', OLD.is_active
    );
    v_new := jsonb_build_object(
      'role', NEW.role,
      'permissions', NEW.permissions,
      'is_active', NEW.is_active
    );

    INSERT INTO staff_audit_logs (actor_user_id, target_user_id, account_id, action_type, old_value, new_value)
    VALUES (v_actor_id, NEW.id, NEW.account_id, v_action, v_old, v_new);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS users_audit_trigger ON users;
CREATE TRIGGER users_audit_trigger
  AFTER INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION log_user_changes();
