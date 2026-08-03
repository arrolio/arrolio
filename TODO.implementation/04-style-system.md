---
priority: P0
phase: 1
depends_on: [02]
layer: foundation
est: 2d
status: in_progress
---

## Problem

Style declarations need a typed representation that supports:
- Inheritance (parent style → child override).
- Resolution by name (`:body`, `:heading_1`) or selector.
- Medium-aware properties (font, color, alignment, spacing).
- Diff/merge for span-style overrides within paragraphs.

## Approach

Files under `lib/arrolio/style/`:

- `definition.rb` — immutable struct of resolved properties
  (font_name, font_size, fill_color, stroke_color, line_spacing,
  align, valign, margin, padding, character_spacing, word_spacing,
  keep_together, page_break_before, page_break_after, line_break).
- `registry.rb` — name → Definition map; resolves lookups;
  supports `register(name, **props)` and `resolve(name)`.
- `diff.rb` — given a base Definition + a hash of overrides, produce
  a new Definition (used for inline span styling).
- `table_style.rb`, `row_style.rb`, `cell_style.rb` — table-specific
  subclasses.

Defaults:
- `font_name: "Helvetica"`, `font_size: 12`, `align: :left`,
  `line_spacing: 1.2`, `line_break: :greedy`.

## Done-When

- [ ] `Style::Registry.new` accepts a hash of definitions.
- [ ] `registry.resolve(:body)` returns a `Definition`.
- [ ] `definition.with(font_size: 14)` returns a new merged Definition.
- [ ] Inheritance: child without `font_size` inherits parent's.
- [ ] Specs cover registration, resolution, merge, inheritance.
