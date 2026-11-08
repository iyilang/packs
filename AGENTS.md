# iyipacks

Do not pollute commit messages with co authored by Agents.

A catalog site of the iyi standard library and the iyi modules on GitHub,
served by `packs.iyi` (iyi-web) from the SQLite file `data/packs.db`
(iyi-db, iyi-sqlite).

The live site is available at <https://packs.iyi.dev>.

- The HTML is in `.eiy` templates under `src/views/`, rendered by iyi-web's
  `render`. `<%= %>` escapes; `raw(...)` is the only way past it and only
  takes markup the program built.
- The schema and the hand-written catalog (categories, the standard
  library, overrides) are miyrate migrations in `db/migrations`. A released
  migration is never edited: a catalog change is a new one,
  `make migration NAME=...`.
- `make update` imports the iyi modules on GitHub into `data/packs.db`;
  corrections go in the `overrides` table, through a migration.
- `make serve` runs the site at <http://localhost:3000>.
- `make check` and `make test` must pass.
