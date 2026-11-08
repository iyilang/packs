# iyipacks

The website is available at [https://packs.iyi.dev](https://packs.iyi.dev).

A package directory written in iyi, inspired by the
[Ruby Toolbox](https://www.ruby-toolbox.com/). One iyi program serves it:
[iyi-web](https://github.com/sdogruyol/iyi-web) answers the requests and
renders the pages, and the catalog lives in one SQLite file,
`data/packs.db`, read through [iyi-db](https://github.com/iyilang/db) and
[iyi-sqlite](https://github.com/iyilang/sqlite). Its schema and the
hand-written part of the catalog are
[miyrate](https://github.com/iyilang/miyrate) migrations.

This is a rewrite of the static site generator that served packs.iyi.dev
before: the same pages, data and import rules, with search, filtering and
sorting done by the server.

## Getting started

Requirements: **iyi 0.20.1 or later**, `make`, and the SQLite library:

- **Linux:** `apt install libsqlite3-dev`.
- **macOS:** the system's.
- **Windows:** `sqlite3.lib` and `sqlite3.dll` in a directory named by
  `IYI_LIBRARY_PATH`. Take `sqlite-dll-win-x64-*.zip` from SQLite's
  [download page](https://sqlite.org/download.html) and make the import
  library in a Visual Studio developer prompt:
  `lib /def:sqlite3.def /out:sqlite3.lib /machine:x64`.

From the project root:

```sh
make serve       # http://localhost:3000
make update      # fills the catalog with the iyi modules on GitHub
```

`data/packs.db` is not in git. The first start creates it and applies the
migrations, which bring the categories and the standard library; `make
update` adds the modules on GitHub. The server applies pending migrations
before it listens.

`PACKS_PORT` sets the port the site listens on: `PACKS_PORT=8080 make serve`.
`-p` on the command line comes before it, and iyi-web's `PORT` after it.
`PACKS_URL` is the address the site is served at, `https://packs.iyi.dev`
unless set; canonical links, the sitemap and link previews use it.
`DATABASE_URL` names another catalog, e.g.
`DATABASE_URL='sqlite3:./other.db?foreign_keys=on'`. `IYI_WEB_ENV=production`
hides error details from visitors.

## Routes

| Path | |
|---|---|
| `/` | Every package; `?q=`, `?category=` and `?sort=` (`name`, `reverse`, `stars`, `used`, `updated`) search, filter and sort |
| `/categories/:slug` | One category |
| `/packages/:slug` | A package: install command, source, GitHub numbers, what it requires and what uses it, its README |
| `/about` | About the directory |
| `/packages.json` | The catalog as JSON |
| `/sitemap.xml`, `/robots.txt` | For search engines |
| `/llms.txt` | The directory in Markdown for language models ([llmstxt.org](https://llmstxt.org)) |
| `/health` | `ok` when the catalog can be read, 503 otherwise |

The addresses of the old static site (`/packages/http/index.html`, ...)
redirect to these. Every page works without JavaScript; `public/app.js`
adds the `/` search shortcut and applies a filter as soon as it is chosen.
Every response carries a Content Security Policy, and every value a
template prints is HTML-escaped.

## Search engines

- Every page has its own title, description and canonical address, and
  Open Graph and Twitter tags with `public/og.png` as its card.
- A search or another sort order is `noindex, follow`: crawlers follow
  its links, and the plain listing is the page that is listed.
  `/?category=web` names `/categories/web` as its canonical address.
- JSON-LD: `WebSite` on the listing, `CollectionPage` and `BreadcrumbList`
  on a category, `SoftwareSourceCode` and `BreadcrumbList` on a package.
- `/sitemap.xml` lists the listing, every category and package (a module
  with its last push as `lastmod`) and the about page; `robots.txt` names it.
- Package pages link to each other: the modules a package requires, and
  the listed modules that require it.
- A module's README is imported with it and rendered as a safe subset of
  Markdown (`src/markdown.iyi`): headings, lists, code, tables, quotes and
  links. Raw HTML and images are left out, everything else is escaped, a
  link goes to http(s) or mailto only and carries `rel="nofollow ugc"`.
- Responses are compressed (zstd or gzip). Pages are cached for five
  minutes; the stylesheet and the script are linked with their content's
  version and cached for a year.

## The catalog

| Table | Written by |
|---|---|
| `categories` | migrations |
| `packages` | migrations (the standard library) and `make update` (the modules on GitHub) |
| `overrides` | migrations: a non-NULL `category`, `description` or `note` replaces the imported one, `hidden = 1` leaves the module out |

The site reads the `listed` view: the packages with their overrides
applied and the hidden ones left out. Packages from GitHub come first and
the standard library after them, each by name.

### Changing the hand-written part

Categories, the standard library and overrides change through a new
migration; a migration that was released is never edited:

```sh
make migration NAME=hide_some_module   # writes db/migrations/<time>_hide_some_module.sql
```

```sql
-- +miyrate Up
INSERT INTO overrides (repo, hidden) VALUES ('someone/some-module', 1);

-- +miyrate Down
DELETE FROM overrides WHERE repo = 'someone/some-module';
```

```sh
make migrate                 # applies it; the server also does when it starts
make migrate ARGS=status     # or down, redo, dbversion
```

A statement ends at a line ending in `;`.

### Importing the modules on GitHub

```sh
GITHUB_TOKEN=… make update
```

The token may also be kept in `.env` in the project root, as a line
`GITHUB_TOKEN=…`; git ignores that file and the Makefile reads it. A
fine-grained token with read-only access to public repositories and no
permissions is enough.

`make update` (`update.iyi`) looks at four kinds of repository: those with
an `iyi.mod` at their root, found by GitHub code search; those with the
topic `iyi`; those named in `overrides`; and the modules of the last
import. It keeps a repository, archived or not, whose `iyi.mod` says
`module github.com/OWNER/REPO` for itself, or `github.com/OWNER/REPO/vN` for
major version N of 2 or more, as `iyi get` requires; that leaves out
applications, whose `iyi.mod` names no repository, and forks that only copy
a module. For each it records the repository's numbers, the highest
`vMAJOR.MINOR.PATCH` tag of the module's major version (0 or 1 without a
suffix) and its date, the number of contributors (up to 100), and the
modules its `iyi.mod` requires, from which "used by" is
counted. The category comes from the repository's topics, or is `other`.
A module's slug is its repository's name, or `OWNER-NAME` when another
module or a standard module has that name.

The requests go through `curl`, and the token is given to curl on its
standard input; only the API gets it. Without `GITHUB_TOKEN` code search is
skipped and GitHub allows 60 requests an hour, enough for a handful of
modules. When GitHub does not answer for a module, its record from the last
run is kept; a token GitHub rejects (401) or the rate limit stops the run
without writing anything.

An organization may refuse a token for its repositories alone, as one that
forbids fine-grained tokens with a lifetime over 366 days or enforces SAML
single sign-on does (403). The import then says so once and reads that
organization's repositories without the token, under the 60 requests an
hour; a module it cannot read that way keeps its record from the last run.

The imported modules are replaced in one transaction, so a running server
never shows half an import. The catalog is in SQLite's WAL mode, so the
server's readers never keep the import from committing.

Downloads are not counted: `iyi get` fetches from git, which no one can see.

## Validation

```sh
make check       # type-checks the server, the import and the migration tool
make test        # the import rules, and every route against a scratch catalog
```

`site_test.iyi` migrates a scratch catalog in `.cache/`, adds modules and
overrides, and sends requests through the router in-process: listing order,
categories, search, sorting, escaping, package pages, JSON, redirects, 404s,
and the 503 page when the catalog cannot be read.

iyi-sqlite 0.3.1 builds with one warning from inside the driver
(`REGEXP_FN`, at `sqlite/core.iyi:201`, reached from the pool's connection
factory on every worker); the fix belongs in the driver.

## Project layout

- `packs.iyi`: the server; `update.iyi`: the GitHub import; `migrate.iyi`:
  miyrate's command line.
- `src/storage.iyi`: opens the catalog and applies the migrations.
- `src/catalog.iyi`: the row types and the queries.
- `src/site.iyi`: the routes, the pages and their helpers.
- `src/modules.iyi`: the import rules, and the dates shown.
- `src/github.iyi`: which of GitHub's refusals stop the import.
- `src/seo.iyi`: page metadata, JSON-LD, the sitemap and robots.txt.
- `src/markdown.iyi`: READMEs as HTML.
- `src/views/`: the `.eiy` templates.
- `db/migrations/`: the schema and the hand-written catalog.
- `data/packs.db`: the catalog, not in git.
- `public/`: CSS, JavaScript, the logo and the link preview card, served as static files.
- `modules_test.iyi`, `github_test.iyi`, `markdown_test.iyi`, `site_test.iyi`: the tests.

## Design

The color palette comes from
[iyi.dev’s stylesheet](https://iyi.dev/_astro/Page.CPHo-8Vg.css): white paper,
neutral gray surfaces, and red accents in light mode; charcoal surfaces and
coral accents in dark mode. The theme follows the system color preference.
Font stacks follow the same reference: Figtree and IBM Plex Mono with system
fallbacks; font files are not bundled.

## License

MIT, see [LICENSE](LICENSE).

## Thanks

Thanks to [Domify](https://github.com/domify), who wrote the original
[iyipacks website](https://github.com/domify/iyipacks-website): its design,
its pages and its catalog are the ground this rewrite stands on.
