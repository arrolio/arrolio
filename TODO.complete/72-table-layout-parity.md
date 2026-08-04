---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: pending
est: 5d
---

## Problem

Tables render as plain paragraphs. Multiple pages show table cell
content flowing as sequential text lines (e.g., page 6: "Peripheral
devices, Key(s) or Keyboard to operate" — these are separate table
cells, not a paragraph). The reference renders proper tables with:

- Column borders
- Cell padding
- Row min-height (`table-row-style: min-height 8.3mm`)
- Header row in bold
- Cell text alignment

## Approach

1. **`TableFlowable` must implement actual table layout**: compute
   column widths via `Table::AutoLayout`, place each cell as a
   sub-frame, render cell borders, and emit placed boxes that the
   renderer can draw.
2. **Cell rendering**: each cell is a mini-frame with its own text
   layout. The cell's paragraphs are laid out within the cell width,
   with padding (left/right/top/bottom).
3. **Borders**: draw line operators around each cell / row / table.
   The renderer needs `render_rect` or `render_line` support (already
   partially exists).
4. **Row splitting**: when a table row doesn't fit on the current
   page, split it: some cells on this page, rest on next. Match FOP's
   behavior of repeating the header row on continuation pages.
5. **Spanned cells**: handle `colspan` and `rowspan` (already in the
   Content::Table::Cell model, just not rendered).

## Expected improvement

Fixes every page that contains a table (pages 6, 8, 20, 23, 24, 27).
Estimated 10–15% overall similarity improvement.

## Done-When

- [ ] `TableFlowable#emit` places cells in a grid (not as sequential
      paragraphs)
- [ ] Column widths computed via `Table::AutoLayout`
- [ ] Cell borders rendered
- [ ] Row min-height respected
- [ ] Header row repeated on table continuation pages
- [ ] Tables on pages 6, 20, 23, 27 render visibly as tables
