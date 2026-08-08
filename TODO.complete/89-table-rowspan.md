---
priority: P1
impact: high
depends_on: [72]
layer: flowable
status: in_progress
est: 2d
---

## Problem

Table cells with `colspan` render correctly, but `rowspan` (cells
spanning multiple rows) are not supported. This causes tables with
merged vertical cells to render with missing or misaligned content.

## Current state

- `colspan`: SHIPPED in `TableFlowable#render_row`
- `rowspan`: NOT implemented
- Table caption continuation ("Table X (continued)"): SHIPPED
- Bold header cells: SHIPPED
- Row min_height: SHIPPED

## Approach

1. **Track rowspan in the table model.** `Content::Table::Cell` needs
   a `rowspan` attribute (default 1).

2. **Grid-based layout.** The `AutoLayout` needs to maintain a grid
   where occupied cells (from rowspan) are skipped during rendering.

3. **Render cell with increased height.** A cell with rowspan=2 spans
   two row heights. The renderer draws it once at the top row's
   position with height = sum of spanned rows.

4. **Skip occupied cells.** When rendering subsequent rows, cells that
   are covered by a rowspan from above are skipped.

## Done-When

- [ ] `<td rowspan="2">` renders as a cell spanning 2 rows
- [ ] Subsequent rows skip cells covered by rowspan
- [ ] Cell content vertically centered in spanned area
- [ ] Specs cover rowspan + colspan combinations
- [ ] OIML Table 1-6 render correctly

## Measurement

Affects Table 1 (accuracy classes) and Table 6 (load symbols).
Last measured: 2026-08-08.
