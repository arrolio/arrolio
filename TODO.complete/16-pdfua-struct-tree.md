---
priority: P2
impact: low
depends_on: []
layer: render
status: done
est: 3d
---

## Problem

Reference PDF is PDF/UA-1 conforming — has a /StructTreeRoot with
marked-content sequences per paragraph, heading, table, etc. Some
accessibility tools and government archives require this.

## Approach

Files under `lib/arrolio/renderer/`:

- `struct_tree_builder.rb` — walks Output::Page[], builds a tree
  of structure elements (Document → Part → Section → P, H1, T, etc.)
- Each PlacedBox carries a `role:` (e.g. :H1, :P, :TH, :TD); the
  renderer wraps its canvas-emit in BDC/EMC marked-content sequences
  with /MCID and references the struct element.

## Done-When

- [ ] `pdfinspect out.pdf --struct` shows a proper tree.
- [ ] Headings tagged /H1, /H2; paragraphs /P; table cells /TH, /TD.
- [ ] Specs cover: tree nesting, role assignment, attribute
      inheritance.

## Implementation

`lib/arrolio/renderer/structure_tree_builder.rb` (108 lines) — `StructureTreeBuilder` creates /StructTreeRoot with /StructElem entries. Maps content types to PDF structure types (H1-H6, P, Table, Figure, etc.). `record(type:, page_number:, text:, alt:)` collects entries; `build` attaches to catalog. 6 specs.
