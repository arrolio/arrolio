---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

`TableFlowable` already does basic grid layout. What was missing:

- **Cell structure loss on split** — `rebuild_table` mapped each
  cell to its `.text` string, losing colspan/rowspan/style_id.
  Second splits then produced wrong column counts.
- **Header cells weren't bold** — no styling distinction between
  header and body cells.
- **Cell align ignored** — cells declaring `align: :center` or
  `:right` were left-aligned.
- **Header repetition on continuation** — already worked (the
  tail table included the original header).
- **`"Table N (continued)"` caption** — not implemented.
- **Row min-height** — currently uses a magic 4pt; the XSL
  specifies `min-height 8.3mm` per row.

## Status (2026-08-05)

- [x] **`rebuild_table` preserves Row/Cell objects** — passes the
      original header and body through `Content::Table.new`,
      keeping all cell metadata.
- [x] **Header cells render with Bold variant** — `cell_style`
      takes a `header:` flag and returns the Bold font variant
      for header rows.
- [x] **Cell `align` respected** — `render_cell` applies
      `style.with(align: cell.align || style.align)`.
- [x] **Header cell border heavier** — 0.7pt vs 0.5pt for body
      cells, matching FOP's visual hierarchy.

## Still pending

- [ ] **Continuation caption "Table N (continued)"** on
      continuation pages — emit a TextFlowable above the
      repeated header on splits.
- [ ] **Row min-height from XSL** — read
      `table-row-style: min-height 8.3mm` from layout_spec and
      use it instead of the 4pt magic number.
- [ ] **`colspan` rendering** — `Table::AutoLayout` already
      allocates widths for colspan; the renderer needs to merge
      cells and skip inner borders.
- [ ] **`rowspan` rendering** — currently ignored; needs vertical
      merge with skip-borders logic.

## Done-When

- [x] `TableFlowable#do_split` preserves cell metadata across splits
- [x] Header cells render bold with heavier border
- [x] Cell `align` respected
- [ ] "Table N (continued)" caption emits on continuation pages
- [ ] Row min-height from layout_spec
- [ ] `colspan` cells span multiple columns visually
- [ ] Page 18+ similarity improves from 25-40% to >60%

## Measurement

`bundle exec rake parity:check` — table pages currently mixed:
page 20 +18pp (table content visible), page 21 -23pp (column
width shift). Net -0.4% overall. Visual quality on table pages
improved substantially.
