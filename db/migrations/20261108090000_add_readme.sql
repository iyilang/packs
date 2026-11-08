-- +miyrate Up
-- A module's README (Markdown, as GitHub serves it) and the address its
-- relative links are read against: the README's directory on GitHub.
ALTER TABLE packages ADD COLUMN readme TEXT NOT NULL DEFAULT '';
ALTER TABLE packages ADD COLUMN readme_base TEXT NOT NULL DEFAULT '';

-- +miyrate Down
ALTER TABLE packages DROP COLUMN readme_base;
ALTER TABLE packages DROP COLUMN readme;
