---
priority: P1
impact: med
depends_on: [70]
layer: flowable
status: pending
est: 3d
---

## Problem

ToC pages show entries with leader dots but wrong page numbers
(because pagination is off). Even after pagination is fixed by TODO
70, the ToC needs proper leader rendering: right-aligned page numbers
connected to the entry text by a line of dots.

Currently `TocLineFlowable` renders the entry text + page number as
a single text line. The reference renders a leader (dotted line)
between the text and the page number, with the page number
right-aligned at the margin.

## Approach

1. **Leader rendering**: add a `leader` property to `TextFlowable`
   (or a new `LeaderFlowable`) that fills the gap between the end of
   the entry text and the right margin with dots (or other leader
   characters). The XSL uses `leader-pattern="dots"`.
2. **Right-aligned page number**: the page number is positioned at
   `text-align="right"` within the ToC entry line. The leader fills
   the space between.
3. **Level-based indentation**: ToC entries at level ≥2 are indented
   by 12pt (already configured in `toc_entry_sub` style, but the
   flowable must apply the style).
4. **Bold level-1 entries**: the XSL's `refine_toc-leader-style`
   sets `font-weight="bold"` for level-1 entries.

## Expected improvement

Fixes pages 3–4 (ToC pages) from 0.6% to ~80%.

## Done-When

- [ ] Leader dots render between entry text and page number
- [ ] Page numbers are right-aligned at the right margin
- [ ] Level ≥2 entries are indented
- [ ] Level-1 entries are bold
- [ ] ToC page numbers match the reference (after TODO 70 fixes
      pagination)
