---
priority: P3
impact: low
depends_on: []
layer: foundation
status: done
est: 1d
---

## Problem

Arrolio's `class Arrolio::Foo::Bar` (compact-form) class
declarations break Ruby's lexical constant lookup. Sibling
constants referenced by short name (e.g. `Output::Page` inside
`class Engine::Paged`) don't trigger autoload. As a workaround,
internal `require "arrolio/..."` calls were added — those violate
the project rule (autoload only).

## Approach

1. Convert every `class Arrolio::Foo::Bar` declaration to nested
   form `module Arrolio; module Foo; class Bar`.
2. Remove every `require "arrolio/..."` line from internal files.
3. Verify autoload chain works: every reference to a sibling
   constant finds it via lexical scope → Arrolio → autoload fires.
4. Update `.rubocop.yml` to enforce `Style/ClassAndModuleChildren:
   EnforcedStyle: nested` and enable the cop (so future
   auto-corrects don't regress).

## Done-When

- [ ] `grep -rE '^class Arrolio::|^module Arrolio::' lib/`
      returns empty.
- [ ] `grep -rE '^require "arrolio/' lib/` returns empty.
- [ ] All 29+ specs pass.
- [ ] OIML pipeline still produces same PDF.
- [ ] `.rubocop.yml` enforces nested style; new code can't regress.

## Implementation

All files use nested `module Arroolio; class Foo` style. No compact `class Arroolio::Foo`.
