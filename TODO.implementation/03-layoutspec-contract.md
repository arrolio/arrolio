---
priority: P0
phase: 1
depends_on: [02]
layer: foundation
est: 2d
status: in_progress
---

## Problem

Engine and Renderer both need a typed layout description to drive
placement. This is the Ruby equivalent of XSL-FO's
`fo:layout-master-set` + `fo:page-sequence-master` — but as Ruby
objects, no XML.

## Approach

Files under `lib/arrolio/layout_spec/`:

- `layout_spec.rb` — top container; holds `page_templates`, `styles`,
  `flows`, `page_sequences`.
- `page_template.rb` — name, page_size, margins, region_extents,
  computed `regions`.
- `region.rb` — name (`:body`, `:before`, `:after`, `:start`, `:end`),
  geometry, `flow_ref`.
- `page_sequence_master.rb` — selection rules (`:first`, `:odd`,
  `:even`, `:blank`, `:last`).
- `flow.rb` — name, source (path into Content tree), default style.

DSL: `LayoutSpec.build { page_template(:body) { ... }; style(:body, ...) }`.

Validation in constructor — raise `LayoutSpecError` on:
- Unknown region name.
- Page size that isn't a 2-element Array of positives.
- Margin that's negative.
- Style reference to a name not in the registry.

## Done-When

- [ ] `LayoutSpec.build` produces an immutable spec.
- [ ] `spec.page_template(:body)` returns a `PageTemplate`.
- [ ] `spec.style(:body)` returns a resolved `Style::Definition`.
- [ ] Invalid specs raise `LayoutSpecError` with a useful message and
      a `spec_field` attribute pointing at the offending field.
- [ ] Specs cover happy path + every validation rule.
