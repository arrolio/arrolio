---
priority: P0
phase: 8
depends_on: [28, 22]
layer: table
est: 2d
status: pending
---

## Problem

Given a resolved grid (column widths + cell rects), render the table:
draw borders as a single-line grid (border-collapse model), fill
backgrounds, place each cell's content via its flowables. The
renderer must produce `PlacedBox[]` entries that the PDF renderer
(TODO 22) consumes.

## Approach

File: `lib/arrolio/table_renderer.rb`.

```ruby
class Arrolio::TableRenderer
  def initialize(table, grid)
  def render(canvas, x_origin, y_origin, context) -> Float (total height)
end
```

Steps:
1. **Backgrounds**: for each row, fill the row's rect with the row's
   `background_color` (or table's `header_background` for header rows).
2. **Borders**: border-collapse grid.
   - Vertical lines: at each column boundary (including outer left/right).
   - Horizontal lines: at each row boundary (including outer top/bottom).
   - Stroke colour from `table.style.border_color`; width from
     `table.style.border_width`.
3. **Content**: for each cell, stack its flowables vertically inside
   the cell rect (accounting for `cell_padding`).

Output: emits `canvas` operations directly OR returns PlacedBox[]
(we'll do canvas operations directly for simplicity; the PlacedBox
indirection is for non-PDF renderers, deferred).

PDF coordinate flip: PDF y grows up; table y grows down. Convert via
`y_origin - rect.y - rect.height`.

## Done-When

- [ ] A 2×2 table renders as a visible grid with content in each cell.
- [ ] Header row background differs from body rows when
      `header_background` is set.
- [ ] Border-collapse: adjacent cells share a single 1pt line, not
      doubled.
- [ ] Cell content respects `cell_padding`.
- [ ] Colspan cell spans the combined width visually.
