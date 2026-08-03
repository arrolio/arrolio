---
priority: P0
impact: high
depends_on: [50, 51]
layer: architecture
status: done
est: 1d
---

## Problem

The arrolio gem packaged OIML flavor artifacts in its own source tree
(`data/oiml/`). When consumers installed the gem, they got OIML
configuration they did not ask for. Worse, the gem could not be used
for any other flavor without the OIML artifacts being present. This
violated OCP and the principle that a layout engine is flavor-neutral.

## Approach

1. **Moved** `data/oiml/` → `flavors/oiml/` (sibling of `lib/`, outside
   the gemspec's packaged file list).
2. **Excluded** `flavors/` from the gemspec: `spec.files` rejects any
   path starting with `flavors/`.
3. **Replaced** the flavor-specific `:oiml` Rake namespace with a
   generic `:flavor :generate` task that accepts `XSL=` and `OUT=`.
4. **Replaced** `exe/oiml2pdf` with a generic `exe/arrolio2pdf` that
   takes a flavor directory argument or `ARROLIO_FLAVOR_DIR` env var.
5. **Deleted** OIML-specific scripts (`run_oiml.py`, `run_diff.py`,
   `write_arrolio_files*.py`, `xsl_to_layout.rb`).
6. **Added** a synthetic sample flavor at
   `spec/fixtures/flavors/sample/` so the gem's own tests are
   flavor-neutral.
7. **OCP specs** verify (a) no flavor autoload in core, (b) no
   flavor-named Ruby under `lib/`, (c) the gemspec excludes `flavors/`.

## Done-When

- [x] `gem build arrolio.gemspec` produces a gem with no `flavors/` files
- [x] `lib/` contains no `oiml|iso|iec|bsi` named files
- [x] `lib/arrolio.rb` has no flavor autoloads
- [x] Rakefile has no flavor-specific tasks
- [x] CLI takes flavor directory as an argument (no hardcoded flavor)
- [x] Gem specs run without any external flavor installed

## Verification

- OCP specs in `spec/arrolio/flavor_spec.rb`
- `bundle exec rake` is green
- `gem build` and `gem contents` show no `flavors/` artifacts
