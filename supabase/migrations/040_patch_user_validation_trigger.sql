-- Migration: 040_patch_user_validation_trigger.sql
-- Description: Patch validate_user_update to prevent non-admins from modifying their own id and is_active status.

BEGIN;

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

  -- Non-admins cannot elevate privileges or modify critical fields
  IF NOT has_role('admin') THEN
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'Cannot modify user ID.';
    END IF;
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Only admins can modify roles.';
    END IF;
    IF NEW.permissions IS DISTINCT FROM OLD.permissions THEN
      RAISE EXCEPTION 'Only admins can modify permissions.';
    END IF;
    IF NEW.account_id IS DISTINCT FROM OLD.account_id THEN
      RAISE EXCEPTION 'Cannot modify account association.';
    END IF;
    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'Only admins can modify active status.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
