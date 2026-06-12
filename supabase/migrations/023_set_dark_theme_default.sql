-- Revert default theme back to dark_luxury for existing rows
ALTER TABLE app_settings ALTER COLUMN theme_mode SET DEFAULT 'dark_luxury';

UPDATE app_settings SET theme_mode = 'dark_luxury' WHERE theme_mode = 'light';
