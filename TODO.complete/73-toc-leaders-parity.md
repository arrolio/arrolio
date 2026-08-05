---
priority: P1
impact: med
depends_on: [70, 79]
layer: flowable
status: in_progress
est: 3d
---

## Problem

ToC pages currently render at 51-59% similarity. `TocLineFlowable`
emits "title dots page" as a single text line — the dots fill the
gap correctly, but:

- Page numbers don't right-align to the right margin (they appear
  right after the dots).
- No bold on level-1 entries (XSL `refine_toc-leader-style` sets
  font-weight=bold for top-level entries; we don't).
- Section number formatting off (e.g., our ToC shows "2.1" while
  the XSL emits a tab + "2.1" on its own line for some heading
  levels).

## Approach

1. **`TocLineFlowable#emit` rewrite.** Currently it builds a
   single TextFlowable with the dots inline. Switch to placing
   two `PlacedBox`es per line: one at x=0 (title), one
   right-aligned at x=width-pagew (page number), with a row of
   dots drawn as a third `PlacedBox` (kind: line, repeated) or
   as inline dot characters with computed count.

2. **Level-based styling.** Resolve the style via
   `layout_spec.resolve_style("toc_entry_#{level}")` and apply
   weight=bold for level==1 by setting `style = style.with(font_name: bold_variant)`.

3. **Section-number-aware label.** Currently `TocBuilder` builds
   `label = "#{number} #{title}"`. When the XSL emits "1\n
   Introduction" (number on its own line, title on next), match
   that — but this is rare and only affects some entry levels.
   Defer until page numbers and leaders are correct.

4. **Page-number source.** `entry[:page_number]` comes from
   `FlowContext#record_heading` which is called during
   `Engine::Paged#layout` after the heading flowable is placed.
   Then `populate_toc` injects the ToC flowables AFTER initial
   layout. This double-pass works but is fragile — see TODO 9
   for the long-term design.

## Done-When

- [ ] Leader dots fill the gap between title and page number
- [ ] Page numbers right-align at the right margin
- [ ] Level-1 entries render bold
- [ ] Level ≥2 entries are indented
- [ ] Page 3 similarity improves from 51% to >75%

## Current state (2026-08-05)

Basic leader rendering works (dots between title and number).
Page numbers display but aren't right-aligned. Style distinction
between levels isn't applied.
