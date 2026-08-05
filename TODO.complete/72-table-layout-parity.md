---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

`TableFlowable` already does basic grid layout (column widths via
`Table::AutoLayout`, per-cell `TextFlowable`, cell-border rects).
What's missing:

- **Header row repetition** when a table splits across pages —
  FOP repeats the header on each continuation page; we don't.
- **Row min-height** from `table-row-style: min-height 8.3mm` —
  cells can be shorter than the row min-height; we render at
  natural height.
- `"Table N (continued)"` caption on continuation pages — FOP
  emits this; we don't.
- **Header cell styling** — bold weight, background fill.
- **Cell text alignment** — currently inherits `:body` (justify);
  FOP uses left-align for most table cells.
- **`colspan` / `rowspan` rendering** — `Content::Table::Cell`
  carries these fields; the renderer ignores them.

Pages 5, 6, 18, 19, 20, 23, 24, 27 contain tables. Most of these
are at 30-50% similarity because cell text matches but cell
borders and continuation captions don't.

## Approach

1. **`Content::Table` model additions:**
   - `header_rows` separate from `body_rows` (already split via
     `partition_rows`).
   - `caption_text` for "Table N (continued)" emission.
   - `min_row_height` per row, propagated from XSL attribute set.

2. **`TableFlowable#do_split` — repeat header on continuation.**
   The split logic already exists; it needs to prepend the header
   to the tail table when splitting.

3. **Continuation caption flowable** — emit a `TextFlowable` with
   `Table N (continued)` style at the top of each continuation
   page, between the page header and the table body.

4. **Cell style override** — `cell_style(cell)` should consult
   `cell.style_id` (already on the model) instead of forcing the
   table's `@style`. Add a `:table_header_cell` style (bold,
   centered) and a `:table_body_cell` style (left-aligned).

5. **`colspan` / `rowspan` rendering** — `Table::AutoLayout`
   already allocates widths for colspan. The renderer needs to
   merge cells and skip the inner border lines.

6. **Row min-height** — `row_height` already returns
   `max_h + 4.0`. Replace the magic 4.0 with `row.min_height ||
   cell_padding`.

## Done-When

- [ ] `TableFlowable#do_split` prepends header to tail when splitting
- [ ] "Table N (continued)" caption emits on continuation pages
- [ ] Header cells render bold + centered (not justified)
- [ ] Row min-height respected (no more 4.0 magic number)
- [ ] `colspan` cells span multiple columns visually
- [ ] Tables on pages 6, 19, 20, 23 render visibly as bordered grids
- [ ] Page 18+ similarity improves from 25-40% to >60%

## Expected improvement

Pages 5-6, 18-20, 23-24, 27 — estimated +10% overall similarity.
