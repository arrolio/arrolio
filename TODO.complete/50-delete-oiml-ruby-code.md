---
priority: P0
impact: high
depends_on: [48, 49, 51, 52]
layer: architecture
status: done
est: 5d
---

## Problem

The OIML flavor had **1805 lines of Ruby code** in `lib/arrolio/oiml/`
plus **three YAML files** in `data/oiml/`. Both were inside the arrolio
gem package, violating the user's principle: "OIML FLAVOR SHOULD ONLY
BE CONFIGURATION — NO CODE!" Flavors must live OUTSIDE the gem so the
gem is open for extension (new flavors) without modification.

## Approach

1. **Generic runtime** (in core): `Arroolio::GenericAdapter`,
   `Arroolio::GenericFlowBuilder`, `Arroolio::ConfigDrivenPipeline`,
   `Arroolio::AssetResolver`, `Arroolio::TocBuilder`. All flavor-agnostic.
2. **XSL → config generator** (`scripts/xsl_to_config.rb`): reads the
   authoritative stylesheet and emits all three YAML files.
3. **OIML flavor moved** from `data/oiml/` to `flavors/oiml/` (outside
   the gem package).
4. **Legacy OIML Ruby deleted**: `lib/arrolio/oiml*` (~1805 lines),
   `spec/arrolio/oiml/`, `exe/oiml2pdf`, `exe/oiml-diff`,
   `scripts/run_oiml.py`, `scripts/run_diff.py`,
   `scripts/xsl_to_layout.rb`, `scripts/write_arrolio_files*.py`.
5. **Generic CLI** `exe/arrolio2pdf` takes a flavor directory argument;
   no flavor is hardcoded.
6. **Synthetic sample fixture** at `spec/fixtures/flavors/sample/` keeps
   the gem's own tests flavor-neutral (no OIML dependency).
7. **Rakefile** namespace `:flavor :generate` is flavor-agnostic.
8. **gemspec** excludes `flavors/` from the packaged files list.

## Done-When

- [x] `Arroolio::ConfigDrivenPipeline` class implemented
- [x] Pipeline uses GenericAdapter + GenericFlowBuilder + TocBuilder
- [x] `lib/arrolio/oiml/` is deleted (0 Ruby files in the gem)
- [x] OIML flavor = 3 YAML files + 0 lines of Ruby
- [x] Real OIML fixture renders via generic pipeline
- [x] OCP spec asserts no flavor files are packaged by the gemspec
- [x] All specs pass with the new pipeline

## Verification

- `bundle exec rspec` → 232 examples, 0 failures
- `bundle exec ruby exe/arrolio2pdf <fixture> out.pdf flavors/oiml` → 194KB PDF
- `Arroolio::ConfigDrivenPipeline.new(flavor_dir: ...).render` is the
  single entry point; no flavor-specific dispatch in core.
