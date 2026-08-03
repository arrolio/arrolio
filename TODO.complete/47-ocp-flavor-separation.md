---
priority: P0
impact: high
depends_on: []
layer: architecture
status: done
est: 1d
---

## Problem

OIML-specific code lived INSIDE the Arroolio core gem (`lib/arrolio/oiml/`).
This violated OCP — adding a new flavor (ISO, IEC, BSI) would require
modifying the core. The core engine autoloaded `Arroolio::Oiml`, had
hardcoded OIML logo paths, and the OIML module was part of the core
autoload tree.

## Approach

1. **Removed** `autoload :Oiml` from `lib/arrolio.rb` — core no longer
   knows about any specific flavor.
2. **Added** `autoload :Flavor` — core provides the flavor system.
3. **Created** `Arroolio::Flavor::Registry` — flavors register
   themselves at load time.
4. **Removed** `OIML_LOGO_PATHS` constant from the renderer — logo
   paths now come from the flavor's config, not hardcoded.
5. **Documented** OIML module as "NOT part of Arroolio core".
6. **Updated** all consumers (exe/oiml2pdf, scripts, specs) to
   explicitly `require 'arrolio/oiml'`.

## Done-When

- [x] Core `lib/arrolio.rb` does NOT autoload Oiml.
- [x] Core `lib/arrolio.rb` autoloads Flavor.
- [x] No `OIML_LOGO_PATHS` in the renderer.
- [x] OIML module documented as non-core.
- [x] Specs verify OCP boundaries.
- [x] All existing specs still pass.

## Implementation

- `lib/arrolio/flavor.rb` — Flavor module with autoloads.
- `lib/arrolio/flavor/registry.rb` (48 lines) — `Flavor::Registry` with `register`, `for`, `registered?`, `names`, `reset!`.
- `lib/arrolio.rb` — OIML autoload replaced with Flavor autoload. Core documentation updated.
- `lib/arrolio/oiml.rb` — Documentation comment: "NOT part of Arroolio core".
- `lib/arrolio/renderer/pdf.rb` — `OIML_LOGO_PATHS` removed. Logo from config only.
- `exe/oiml2pdf` — Explicit `require 'arrolio/oiml'`.
- `spec/spec_helper.rb` — Explicit `require 'arrolio/oiml'`.
- All OIML specs updated with explicit require.
- 11 specs in `spec/arrolio/flavor_spec.rb` — Registry + OCP boundary verification.
