-- +miyrate Up
-- The categories, in the order the site lists them.
CREATE TABLE categories (
  slug TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  position INTEGER NOT NULL UNIQUE
);

-- Every package: the standard library, written by migrations, and the iyi
-- modules on GitHub, written by `make update`. The GitHub numbers and dates
-- are NULL for a standard module; dates are GitHub's RFC 3339 text.
CREATE TABLE packages (
  slug TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  module TEXT NOT NULL DEFAULT '',
  repo TEXT UNIQUE COLLATE NOCASE,
  category TEXT NOT NULL REFERENCES categories (slug),
  description TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL,
  homepage TEXT NOT NULL DEFAULT '',
  usage TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  license TEXT NOT NULL DEFAULT '',
  distribution TEXT NOT NULL CHECK (distribution IN ('Standard library', 'GitHub')),
  stars INTEGER,
  forks INTEGER,
  issues INTEGER,
  watchers INTEGER,
  contributors TEXT,
  created TEXT,
  pushed TEXT,
  version TEXT NOT NULL DEFAULT '',
  released TEXT NOT NULL DEFAULT '',
  requires TEXT NOT NULL DEFAULT '',
  dependents INTEGER,
  topics TEXT NOT NULL DEFAULT ''
);

-- Corrections to imported modules, by repository: a non-NULL field replaces
-- the imported one, and hidden = 1 leaves the module out of the site. Every
-- repository named here is also looked at by `make update`.
CREATE TABLE overrides (
  repo TEXT PRIMARY KEY COLLATE NOCASE,
  category TEXT REFERENCES categories (slug),
  description TEXT,
  note TEXT,
  hidden INTEGER NOT NULL DEFAULT 0 CHECK (hidden IN (0, 1))
);

-- The packages the site shows, with the overrides applied.
CREATE VIEW listed AS
SELECT p.slug, p.name, p.module, p.repo,
       COALESCE(o.category, p.category) AS category,
       COALESCE(o.description, p.description) AS description,
       p.source, p.homepage, p.usage,
       COALESCE(o.note, p.note) AS note,
       p.license, p.distribution, p.stars, p.forks, p.issues, p.watchers,
       p.contributors, p.created, p.pushed, p.version, p.released,
       p.requires, p.dependents, p.topics
FROM packages p
LEFT JOIN overrides o ON o.repo = p.repo
WHERE COALESCE(o.hidden, 0) = 0;

-- +miyrate Down
DROP VIEW listed;
DROP TABLE overrides;
DROP TABLE packages;
DROP TABLE categories;
