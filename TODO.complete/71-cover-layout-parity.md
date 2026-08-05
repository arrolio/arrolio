---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

Page 1 (cover) sits at **48.0%** similarity. The reference cover
uses a complex SVG-based layout:

- Two-column `fo:table` with the doctype word in scaled SVG `<text>`
  (left column) and the docidentifier in scaled SVG `<text>`
  (right column)
- A bordered `fo:block-container` at `top="65mm"` with the title
  (16pt Jost, centered, border-top + border-bottom)
- A second block at `top="214mm"` with the OIML organisation names
  (two-column table: logo left, text right)
- A vertical-orientation block at `left="-63.5mm"` with the full
  docidentifier + edition in rotated text
- All text rendered via SVG `<text>` with `transform="scale(0.82,1)"`
  for a condensed effect

Our cover is a vertical stack of plain text blocks. With fonts
now embedded (TODO 70 done), the text side of the diff is mostly
correct — the remaining gap is purely positional/scaled.

## Status (2026-08-05)

The `Flowables::PositionedBlock` primitive now exists
(`lib/arrolio/flowables/positioned_block.rb`) — it takes
`children:`, `top:`, `left:`, `width:`, `height:` and renders
its children at fixed page-relative coordinates, consuming zero
flow height so siblings continue at the same y.

## Approach (architectural)

1. **`Flowables::PositionedBlock`** ✅ — shipped.

2. **`Flowables::TwoColumnBlock`** — already exists with
   `left_flowables`, `right_flowables`, `left_ratio`. Works for
   the cover header (doctype + docidentifier) and the org footer
   (logo + names).

3. **`Style::Definition#text_transform`** — add a `scale(x, y)`
   field applied by the renderer before drawing glyphs. Translates
   to `Tm` matrix `[sx, 0, 0, sy, x, y]`.

4. **`Flowables::RotatedText`** — text drawn with
   `reference-orientation: 90` (or 270). The renderer emits `Tm`
   with the rotation matrix.

5. **`flow_rules.yml cover_layout` schema** — replace the current
   flat `cover_content` list with a positioned block tree:

```yaml
cover_layout:
  type: positioned
  blocks:
    - type: two_column
      top: 0
      columns:
        - width: 50%
          blocks:
            - type: text
              source: "{{doctype}}"
              font: "Jost"
              font_size: 19
              scale: [0.82, 1]
        - width: 50%
          blocks:
            - type: text
              source: "{{docidentifier}}"
              ...
    - type: bordered_block
      top: 65mm
      ...
```

6. **`GenericFlowBuilder#build_cover_content`** parses the new
   `cover_layout` schema and emits the corresponding flowable tree.
   Falls back to the current flat-list behavior for flavors that
   haven't migrated.

## Done-When

- [x] `Flowables::PositionedBlock` exists with specs
- [ ] `Flowables::TwoColumnBlock` does proper side-by-side layout
      (already exists; verify it composes correctly with
      PositionedBlock)
- [ ] `Style::Definition` carries `text_transform: [sx, sy]`
- [ ] Renderer applies the scale transform via Tm matrix
- [ ] `Flowables::RotatedText` exists with specs
- [ ] `flavors/oiml/flow_rules.yml` migrated to `cover_layout` schema
- [ ] Page 1 similarity > 60%

## Expected improvement

Page 1 from 48% to ~75% (text already matches; layout needs the
positioned blocks). +1% overall.
