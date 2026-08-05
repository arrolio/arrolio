---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: pending
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

Our cover is a vertical stack of plain text blocks (text content
matches; layout doesn't). With fonts now embedded (TODO 70 done),
the text side of the diff is mostly correct — the remaining gap is
purely positional/scaled.

## Approach (architectural)

The cover layout is defined imperatively in `oiml.xsl` lines 33–287.
Encoding it as configuration requires new flowable primitives:

1. **`Flowables::PositionedBlock`** — absolute-positioned region
   within the page. Carries `top`, `left`, `width`, `height` in
   device units (mm/pt). The engine skips normal flow for these;
   they emit at fixed coordinates.

2. **`Flowables::TwoColumnBlock`** — pair of flowable sequences
   rendered side-by-side. Existing `Flowables::TwoColumnBlock`
   skeleton exists; needs proper width allocation and per-column
   sub-frame.

3. **`Style::Definition#text_transform`** — `scale(x, y)` field
   applied by the renderer before drawing glyphs. Translates to
   `canvas.text(..., transform: [sx, 0, 0, sy, x, y])` if the
   renderer supports it.

4. **`Flowables::RotatedText`** — text drawn with
   `reference-orientation: 90` (or 270). The renderer emits
   `Tm` with the rotation matrix.

5. **`flow_rules.yml` cover_content extension** — replace the
   current flat `cover_content` list with a positioned block
   tree:

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

- [ ] `Flowables::PositionedBlock` exists with specs
- [ ] `Flowables::TwoColumnBlock` does proper side-by-side layout
- [ ] `Style::Definition` carries `text_transform: [sx, sy]`
- [ ] Renderer applies the scale transform via Tm matrix
- [ ] `Flowables::RotatedText` exists with specs
- [ ] `flavors/oiml/flow_rules.yml` migrated to `cover_layout` schema
- [ ] Page 1 similarity > 60%

## Expected improvement

Page 1 from 48% to ~75% (text already matches; layout needs the
positioned blocks).
