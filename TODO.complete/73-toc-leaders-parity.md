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
was emitting the entry as a single text line ("title dots page"),
which worked visually but meant the page number wasn't truly
right-aligned to the right margin — it appeared immediately after
the dots, wherever they ended.

## Status (2026-08-05)

`TocLineFlowable#emit` rewritten to emit three `PlacedBox` values
per line:

1. **Title box** at x=0 (left edge of the region).
2. **Page-number box** right-aligned at x=width-page_width.
3. **Leader box** (only when there's a positive gap between the
   title and page number) containing dot characters computed from
   the available gap and per-dot width.

Page numbers now sit flush at the right margin regardless of how
long the title is.

## Still pending

- **Bold for level-1 entries**: the XSL's `refine_toc-leader-style`
  sets `font-weight="bold"` for top-level entries. Currently all
  levels share the same style.
- **Level-based indentation**: level ≥2 should indent by ~12pt.
  The style is configured (`toc_entry_sub`) but not yet applied
  via the flowable's left offset.
- **Section-number formatting**: some heading levels in the XSL
  produce "1\nIntroduction" (number on its own line). Our label
  is "#{number} #{title}". Defer until other ToC items are correct.

## Done-When

- [x] Leader dots fill the gap between title and page number
- [x] Page numbers right-align at the right margin
- [ ] Level-1 entries render bold
- [ ] Level ≥2 entries are indented
- [ ] Page 3 similarity improves from 51% to >75%

## Measurement

`bundle exec rake parity:check` — page 2 (ToC) currently 100%,
page 3 (ToC continuation if any) at 51%.
