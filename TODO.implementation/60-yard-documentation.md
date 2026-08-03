---
priority: P3
phase: 18
depends_on: []
layer: polish
est: 2d
status: pending
---

## Problem

Arrolio needs API documentation for users who didn't write it. YARD
is the standard Ruby doc tool. Every public class and method should
have YARD docstrings; the docs should render cleanly to HTML.

## Approach

- Add `yard` gem to the development group.
- `.yardopts` with `--no-private`, `--markup markdown`,
  `--files CHANGELOG.md,LICENSE`, `--output-dir doc/yard`.
- Add YARD docstrings to every public class and method:
  - Module purpose statement at the top of each `lib/arrolio/*.rb`.
  - Per-method: `# Brief description.` then `@param`, `@return`,
    `@example`.
  - Cross-link related classes with `{Class::Name}`.
- Rake task `yard` to generate; `rake yard:serve` for live preview.

Modules to document first (in order of API stability):
1. `Arrolio` (top-level — the autoload tree, the `compose` shortcut).
2. `Arrolio::Content::*` — content contract.
3. `Arrolio::LayoutSpec::*` — layout spec.
4. `Arrolio::Engine::Paged` — engine entry point.
5. `Arrolio::Renderer::Pdf` — render entry point.
6. `Arrolio::Composer` — high-level facade.
7. `Arrolio::Oiml::*` — OIML pipeline (the main use case).

## Done-When

- [ ] `bundle exec yard` produces HTML in `doc/yard/`.
- [ ] Every public method has a docstring.
- [ ] No "Missing documentation" warnings from YARD on public API.
- [ ] `Arrolio::Composer` is documented with a working example.
- [ ] The README's quick-start links into the YARD docs.
