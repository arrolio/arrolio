---
priority: P0
phase: 8
depends_on: [02, 16]
layer: table
est: 2d
status: in_progress
---

## Problem

Tables are the hardest layout primitive. Need typed Row/Cell/Column
model that the layout algorithms (TODO 28) and renderer (TODO 29)
operate on. Cells can span multiple columns or rows. Header rows
repeat across page breaks.

## Approach

Files under `lib/arrolio/table/`:

- `table.rb` — value object holding `rows` (Array of Row),
  `column_specs` (Array of ColumnSpec), `style` (TableStyle).
  Methods: `num_columns`, `num_rows`, `header_rows`, `body_rows`.

- `row.rb` — `Row = Struct.new(:cells, :header, :style,
  keyword_init: true)`. `header?` alias. Cells is an Array of Cell.

- `cell.rb` — `Cell = Struct.new(:content, :colspan, :rowspan,
  :style, keyword_init: true)`. `content` is a Flowable or String
  (Strings auto-wrapped in TextFlowable). `colspan?`, `rowspan?`
  predicates.

- `column_spec.rb` — `ColumnSpec = Struct.new(:width, :min, :max,
  :auto, keyword_init: true)`. Class methods: `.fixed(width)`,
  `.auto(min:, max:)`. `fixed?` predicate.

Cell flowables: `Cell#flowables` normalises content into a list of
`Flowable` instances. Strings become `TextFlowable` with the cell's
style.

## Done-When

- [ ] Construct a 3-row × 3-column table; verify `num_rows == 3`,
      `num_columns == 3`.
- [ ] A row marked `header: true` appears in `header_rows`.
- [ ] A cell with `colspan: 2` reports `colspan? == true`.
- [ ] String cell content auto-wraps in TextFlowable.
- [ ] Specs cover construction, header detection, span predicates.
