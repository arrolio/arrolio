---
priority: P1
impact: high
depends_on: [72]
layer: flowable
status: done
est: 2d
---

## Problem

Table cells with `rowspan` (cells spanning multiple rows) were not
supported: covered cells shifted into the wrong columns (Table 5's
"Influence factor" column rendered under the p_LC column) and tall
table-cell text was crammed into one overfull line.

## Solution (2026-08-17)

- `Table::Grid` — occupancy grid over a Content::Table honoring
  colspan AND rowspan. Answers cell placement (which column each
  cell really occupies) and which rows are welded together by a
  vertical span. Shared by AutoLayout (natural widths), TableFlowable
  (row heights, placement, splitting).
- `TableFlowable` places every cell at its grid column; a rowspan
  cell is drawn once in its start row with the combined spanned-row
  height, `valign: middle` centers its content (Table 5's "1.0").
- Row heights: single-row cells drive their row; a spanning cell that
  does not fit its span distributes the deficit equally over the
  spanned rows.
- `do_split` splits only at welded-group boundaries — a rowspan cell
  is never cut by a page break. When the first group does not fit
  the remainder, no head is returned and the whole table moves to
  the next page (FOP semantics).
- `Engine::Paged#place` propagates the page state after a
  whole-flowable move (previously the caller kept filling the old
  page and content fell out of document order).

## Done-When

- [x] `<td rowspan="2">` renders as a cell spanning 2 rows
- [x] Subsequent rows skip cells covered by rowspan
- [x] Cell content vertically centered in spanned area
- [x] Specs cover rowspan + colspan combinations
- [x] OIML Table 4 (rowspan header + colspan) and Table 5 (rowspan 9)
      render correctly

## Measurement

Table 5's page similarity 38% → 86% (2026-08-17).
