---
priority: P0
impact: high
depends_on: []
layer: flowable
status: done
est: 3d
---

## Problem

Tables in the OIML doc (Tables 3–6 in section 5; classification
tables in annexes) currently render as plain paragraph text with
cells joined by "    ". Reference has actual cell borders, column
widths, header row repeat, and row splitting across pages. This
is the single biggest similarity gap on body pages.

## Approach

Files under `lib/arrolio/table/`:

- `column_spec.rb` — fixed(width) | auto | proportional(weight).
  Already stubbed in TODO 27.
- `row.rb`, `cell.rb` — value objects (already exist as
  `Content::Table::Row`/`Cell`).
- `grid.rb` — resolved column widths + row heights after layout.
- `fixed_layout.rb` — assign widths from column_specs (or equal
  distribution if none).
- `auto_layout.rb` — measure each cell's natural width, take max
  per column, distribute remaining space proportionally.

Files under `lib/arrolio/flowables/`:

- `table_flowable.rb` — uses Grid to compute row heights, emits
  PlacedBoxes for cell text + PlacedBox rects for borders. Supports
  `split(width, remaining_height, ctx)` for row-aware splitting:
  if a row doesn't fit, the whole row moves to next page; if the
  table has a header, header repeats on the new page.

## Border drawing

Each cell border is 4 PlacedBox(kind: :line) — top, right, bottom,
left — with stroke_width from CellStyle. Skip shared edges between
adjacent cells (collapse borders).

## Done-When

- [ ] Table 4 (Maximum Permissible Errors) in section 5 renders
      with visible borders matching the reference layout.
- [ ] Header row repeats when body breaks across pages.
- [ ] Column widths honour `<col width="...">` from XML.
- [ ] Cells honour colspan/rowspan.
- [ ] Specs cover: fixed layout, auto layout, row split, header
      repeat, border collapse.
- [ ] OIML diff similarity for table-heavy pages jumps from ~25%
      to ≥70%.

## Implementation

`lib/arrolio/flowables/table_flowable.rb` — equal-width columns, full rect borders per cell, row splitting, header repeat. Cell font uses embedded Times New Roman. Auto-layout (content-based widths) is TODO 34.
