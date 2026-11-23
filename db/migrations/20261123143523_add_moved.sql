-- +miyrate Up
-- A slug an imported module had before, as before its repository was
-- renamed, and the repository it names now: /packages/SLUG redirects to the
-- module's page. Written by `make update`.
CREATE TABLE moved (
  slug TEXT PRIMARY KEY,
  repo TEXT NOT NULL COLLATE NOCASE
);

-- +miyrate Down
DROP TABLE moved;
