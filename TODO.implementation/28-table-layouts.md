---
priority: P0
phase: 8
depends_on: [27, 16]
layer: table
est: 3d
status: pending
---

## Problem

Given a Table + target width, compute the column widths and row
heights. Two strategies: Fixed (caller-specified widths) and Auto
(CSS 2.1 §17.5.2.2 — distribute surplus by content).

## Approach

Files under `lib/arrolio/table_layout/`:

- `resolved_grid.rb` — value object: `column_widths`, `row_heights`,
  `cell_rects` (per-cell { x, y, width, height }). `total_width`,
  `total_height`.

- `fixed.rb` — Fixed strategy:
  - Take column widths from specs.
  - Scale proportionally if sum != target_width.
  - Compute each row's height as the max cell content height at the
    cell's resolved width.

- `auto.rb` — Auto strategy (CSS 2.1):
  1. For each cell, measure min-content width (longest unbreakable
     word) and max-content width (single line).
  2. Aggregate to per-column min/max (respecting colspan: distribute
     spanned cell's min/max evenly across spanned columns).
  3. Distribute target_width:
     - If surplus over max: distribute by max-content ratio.
     - If between min and max: distribute by max ratio of the slack.
     - If less than min: each column gets its min (may overflow).
  4. Compute row heights same as Fixed.

Both strategies return a `ResolvedGrid`.

## Done-When

- [ ] Fixed layout: `Fixed.new(table, target_width: 300).layout`
      honours the spec widths.
- [ ] Fixed layout scales when target_width != sum(specs).
- [ ] Auto layout: a column containing "antidisestablishmentarianism"
      gets at least the word's width.
- [ ] Auto layout: narrow column for short content, wide for long.
- [ ] ResolvedGrid.cell_rects respects colspan (cell spans 2 columns'
      combined width) and rowspan.
- [ ] Specs cover both strategies + colspan/rowspan.
