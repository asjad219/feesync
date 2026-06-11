ALTER TABLE app_settings 
ALTER COLUMN theme_mode SET DEFAULT 'light';

-- Optionally, if we want to reset all existing accounts to light mode:
UPDATE app_settings 
SET theme_mode = 'light' 
WHERE theme_mode = 'dark_luxury';
