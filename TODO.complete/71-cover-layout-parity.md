---
priority: P0
impact: high
depends_on: [70]
layer: render
status: pending
est: 5d
---

## Problem

Page 1 (cover) has 0.4% similarity. The reference cover uses a complex
SVG-based layout:

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

Our cover is a simple vertical stack of plain text blocks in
Helvetica. Every piece of cover text is wrong.

## Approach

The cover layout is defined imperatively in `oiml.xsl` (lines 33–287).
Since we cannot execute XSL, we must encode the cover structure as
configuration:

1. **Two-column block** for the header area (doctype left, docid right)
2. **Absolute-positioned block** at specific y-coordinates for the
   title border box
3. **Two-column block** for the organisation footer
4. **Rotated text** for the vertical docidentifier
5. **Text scaling** via a `transform: scale(x, y)` option on
   `TextFlowable`

This requires adding to the flow_rules/config system:

```yaml
cover_layout:
  type: positioned
  blocks:
    - type: two_column
      top: 0
      left_column:
        - type: svg_text
          source: "{{doctype}}"
          font: "Jost"
          font_size: 19
          scale: [0.82, 1]
      right_column:
        - type: svg_text
          source: "{{docidentifier}}"
          font: "Jost SemiBold"
          font_size: 28
          scale: [0.82, 1]
    - type: bordered_block
      top: 65mm
      width: 119mm
      height: 80mm
      border_top: 1pt solid black
      border_bottom: 1pt solid black
      content:
        - type: text
          source: "{{title_main}}"
          font: "Times New Roman"
          font_size: 16
          align: center
    # ... etc
```

## Expected improvement

Fixes page 1 from 0.4% to ~70% (exact text match, layout
approximately right).

## Done-When

- [ ] Cover renders with two-column header (doctype + docidentifier)
- [ ] Title appears in a bordered box at the correct position
- [ ] Organisation names appear at the bottom in two columns
- [ ] Vertical docidentifier text renders on the left margin
- [ ] Text scaling (condensed) is applied
- [ ] Page 1 similarity > 60%
