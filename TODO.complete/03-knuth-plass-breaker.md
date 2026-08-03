---
priority: P1
impact: med
depends_on: [01]
layer: text
status: done
est: 2d
---

## Problem

Arrolio uses Greedy first-fit line breaking. mn2pdf (via Apache
FOP) uses Knuth-Plass optimal breaking. Differences show up as
ragged-right asymmetry and different line counts per paragraph,
which shifts everything downstream.

## Approach

Files under `lib/arrolio/text_layout/`:

- `knuth_plass.rb` — already stubbed in TODO 12 of TODO.implementation.
  Box/Glue/Penalty elements + DP active-set algorithm. Returns the
  same `Line[]` shape Greedy does.
- Refactor `TextFlowable#laid_out` to pick the algorithm from
  `style.line_break` (:greedy | :knuth_plass).

## Done-When

- [ ] KnuthPlass matches hand-computed optimal on a 5-line test case.
- [ ] Forced breaks (`\n`) and infinite penalties work.
- [ ] Specs cover: under-full, over-full, exact-fit, justification
      stretch distribution.
- [ ] OIML body paragraphs lay out with the same line count as the
      reference (within 1 line per 100 paragraphs).

## Implementation

`lib/arrolio/text_layout/knuth_plass/` module with:
- `item.rb` (80 lines) — Box, Glue, Penalty, FINISHED items.
- `item_builder.rb` (100 lines) — converts InlineRun[] to items. Handles words, spaces, hyphens, newlines.
- `breaker.rb` (220 lines) — dynamic programming algorithm. Active-node method with demerits, badness, fitness classes. Adjustment ratio with stretch/shrink. FINISHED item handling with proper demerits.
8 specs. Produces TextLayout::Line[] compatible with Greedy. Not yet wired into TextFlowable (line_break: :knuth_plass).
