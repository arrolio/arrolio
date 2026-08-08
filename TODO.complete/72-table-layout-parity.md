---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

Tables render with correct cell content but lack some FOP-specific
visual features.

## Status (2026-08-08)

- [x] **Cell metadata preserved on split** — rebuild_table passes
      through original Row/Cell objects (colspan, rowspan, style_id).
- [x] **Bold header cells** — cell_style(header: true) returns
      Bold font variant. 0.7pt border stroke.
- [x] **Cell `align` respected** — render_cell applies
      style.with(align: cell.align).
- [x] **Colspan support** — AutoLayout distributes colspan cell
      width across spanned slots. render_row advances by colspan.
      1 spec for column distribution.
- [x] **Continuation caption** — TableFlowable gains continued:
      and caption_text:. Tail of do_split gets continued: true.
      emit renders "Table N (continued)" above repeated header.
      7 specs for min_height + continued + do_split.
- [x] **Row min_height** — Content::Table::Row gains min_height
      attribute. row_height returns [natural, min_height].max.

## Still pending

- [ ] **Rowspan rendering** — needs vertical merge with skip-borders
      logic in render_row.
- [ ] **Covered cell skip** — when a cell spans multiple columns,
      the cells "underneath" should be skipped (not drawn).

## Done-When

- [x] Cell metadata preserved across splits
- [x] Header cells render bold with heavier border
- [x] Cell align respected
- [x] Colspan column-width distribution
- [x] Continuation caption "Table N (continued)"
- [x] Row min_height from model
- [ ] Rowspan vertical merge
- [ ] Covered cells skipped in grid
