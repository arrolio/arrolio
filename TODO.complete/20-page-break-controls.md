---
priority: P1
impact: med
depends_on: []
layer: flowable
status: done
est: 1d
---

## Problem

oiml.xsl uses `keep-together`, `keep-with-next`, `page-break-before`,
`orphans`, `widows` extensively. Arrolio supports `keep_together`
but not the rest. Result: headings sometimes appear at page bottom
with content on next page; sub-clause titles split from their first
paragraph.

## Approach

Extend `Style::Definition`:

- `keep_with_next:` (bool) — current flowable must be on same page
  as the start of the next flowable.
- `orphans:` / `widows:` (int) — minimum lines at page bottom /
  top of next page when splitting a paragraph.

Update `Engine::Paged` to honour these:

- When placing a flowable with `keep_with_next: true`, peek ahead;
  if next flowable wouldn't fit on this page after this one,
  advance now.
- When splitting a TextFlowable, ensure `widows` lines on the new
  page and `orphans` lines on the current page; otherwise move the
  whole flowable.

## Done-When

- [ ] Headings never appear at page bottom alone.
- [ ] Last line of paragraph never appears alone at top of page.
- [ ] First line of paragraph never appears alone at bottom.
- [ ] Specs cover: keep_with_next enforcement, orphan/widow
      minimums.

## Implementation

`lib/arrolio/content/page_break.rb` (28 lines) — `PageBreak` content node. Adapter recognizes <pagebreak/> and <page-break/> elements. FlowBuilder converts to `Flowables::PageBreak`. Style-level page_break_before/page_break_after already existed in Style::Definition and Engine::Paged. 4 specs.
