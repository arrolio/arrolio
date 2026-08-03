---
priority: P0
phase: 1
depends_on: [01]
layer: foundation
est: 2d
status: in_progress
---

## Problem

Arrolio needs a typed content tree to describe documents semantically.
Strings and hashes are too loose — downstream layers (Engine, Renderer)
must dispatch on content type via `is_a?`. The tree is medium-independent:
it has no notion of "page" or "PDF" anywhere.

## Approach

Files to create under `lib/arrolio/content/`:

- `document.rb` — root; holds `metadata` (Hash), `sections` (Array).
- `section.rb` — `title`, `level`, `number`, `id`, `children`.
- `paragraph.rb` — `inline_runs` (Array of InlineRun).
- `inline_run.rb` — `text` + `style_id` (frozen value object).
- `table.rb` — `Row`, `Cell`, `ColumnSpec` (defer to TODO 27 if convenient).
- `list.rb` — `Item` with `marker` + `content` (defer to TODO 31).
- `image.rb` — `src`, `alt`, `natural_size` (defer to TODO 33).
- `cross_reference.rb` — `target_id`, `reference_kind` (defer to TODO 41).

Conventions:
- Every node has a `role` Symbol (e.g. `:heading`, `:paragraph`)
  used by dispatch tables.
- Frozen value objects. Equality by value (`==` and `eql?` and `hash`).
- Children are an Array; leaf text is a String inside `InlineRun`.
- No mutations after construction. Builders accumulate into Arrays,
  then construct the immutable node in one shot.

DSL: `Document.build { section("Intro") { paragraph("Hello") } }`
builder lives in `lib/arrolio/content/builder.rb`.

## Done-When

- [ ] Every content class is a frozen value object with `==`, `eql?`, `hash`.
- [ ] `Arrolio::Content::Document.build { ... }` produces a tree.
- [ ] Visitors (TODO 05) can walk the tree without type-checks beyond `is_a?`.
- [ ] No content class references pages, PDFs, frames, or renderers.
- [ ] Specs cover equality, immutability, child traversal.
