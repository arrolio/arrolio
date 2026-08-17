---
priority: P1
impact: high
depends_on: [89]
layer: flowable
status: done
est: 2d
---

## Problem

Tables rendered with incorrect cell heights and padding (rows 16pt vs
the reference's 25.45pt pitch), table-cell footnotes inlined into the
header cell (inflating the header and the column widths), SVG figures
a third taller than the reference, and captions that could be
orphaned at a page bottom. Tables spanned the wrong pages and shifted
content on pages 19-27.

## Root causes (measured against mn2pdf v2.55, 2026-08-17)

1. The flavor XSL `table-row-style` sets `min-height: 8.3mm` — with
   border/padding allowance the reference row pitch is 25.45pt. Our
   rows had no floor (content + 4pt).
2. `<fn>` inside a table cell is a TABLE FOOTNOTE in the FOP model:
   only a superscript marker stays in the cell, the body renders
   below the table. The adapter inlined the whole body into the cell.
3. FOP sizes viewport-less SVGs (viewBox only) at CSS pixels → PDF
   points (×72/96). We treated viewBox units as points.
4. `do_split` ignored the caption and repeated header rows in the
   head budget, over-filling the page.
5. Table captions were separate flowables and could be orphaned.

## Solution

- Flavor-configurable table geometry in `flow_rules.yml`:
  `table: { min_row_height, cell_padding, footnote_font_size }` —
  OIML calibrated to 25.45 / 3.3 / 9.0 from the XSL + reference.
- Adapter: table-cell `<fn>` elements contribute a superscript marker
  run to the cell (selector `footnote_marker`) and their bodies to
  `Content::Table#footnotes`; the inline run collector takes an
  `exclude:` selector so footnote text never leaks into cells.
- `TableFlowable` renders table footnotes below the last row (marker
  + body, 9pt, 10pt gap) and carries them across splits to the part
  holding the final rows.
- Caption emitted inside `TableFlowable` (full caption on the head,
  "Table N (continued)" on continuations) — never orphaned.
- SVG user-unit dimensions converted px → pt (×0.75) in both the
  adapter (inline SVG viewBox) and the flow builder (external SVG).
- `Content::Table::Cell` gained `valign`; `align`/`valign` parsed
  from the XML cell attributes.

## Done-When

- [x] Row pitch matches the reference (25.45pt floor from config)
- [x] Table footnotes render below the table with an in-cell
      superscript marker
- [x] Figures render at FOP's px→pt scale
- [x] Caption + header + first row group budgeted in do_split
- [x] Continuation caption appears when a table spans pages
- [x] Specs cover footnote extraction, geometry, viewBox scaling

## Measurement

Overall similarity 62.7% → 64.07% (2026-08-17). Table region:
p19 34→61, p21 38→68, p22 42→61, p23 38→86.
Remaining drift documented in TODO 96.
