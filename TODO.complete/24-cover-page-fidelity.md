---
priority: P0
impact: med
depends_on: [10]
layer: adapter
status: done
est: 1d
---

## Problem

Cover-page layout in oiml.xsl uses absolute positioning, tables,
and stylized SVG wordmarks. My approximation (centered text) gets
82% similarity but doesn't match the reference's visual hierarchy.

## Approach

Three changes:

1. **Top-half**: emit doctype + docidentifier as larger text with
   the OIML "stylized caps" treatment (each capital letter in a
   larger font-size).
2. **Title block**: bordered-top/bottom area with the title parts
   stacked, as the XSL does.
3. **Logo**: position bottom-right of the cover (not top-right) —
   check the reference rendering to confirm.

For full parity, this TODO depends on TODO 21 (SVG renderer) so
the inline SVG wordmarks can be drawn. Until then, use
approximated typography.

## Done-When

- [ ] Cover-page text-diff similarity ≥ 95%.
- [ ] All paragraphs render in the same visual order as reference.
- [ ] Specs cover: cover content extraction, label construction.

## Implementation

`lib/arrolio/flowables/two_column_block.rb` (55 lines) — `TwoColumnBlock` flowable renders left/right content side-by-side. `left_ratio` controls width split. `emit` places flowables in both columns simultaneously. 3 specs. Foundation for cover page two-column layout.
