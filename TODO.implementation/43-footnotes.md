---
priority: P2
phase: 13
depends_on: [20]
layer: page
est: 3d
status: pending
---

## Problem

Footnotes: inline reference number in body text, footnote body at
the bottom of the page where the reference appears. The footnote
region shrinks the body frame on that page; footnotes flow into it.
If a footnote doesn't fit, it continues on the next page (with the
body reference pointing to the original page).

## Approach

Files:

- `lib/arrolio/footnote.rb` — `Footnote = Struct.new(:id, :content,
  :marker, keyword_init: true)`. `content` is a Flowable list.

- `lib/arrolio/output/footnote_region.rb` — a special Region placed
  at the bottom of the body, separated by a horizontal rule.

- `lib/arrolio/engine/footnote_collector.rb` — pass-1 hook: when a
  Footnote flowable is placed on page N, register it on page N's
  footnote region. Body frame on page N shrinks by the footnote
  region's height.

Engine integration:
- Pass 1: place body flowables; when a footnote is encountered,
  compute its height; reserve space at the bottom of the current
  page's body; place the footnote content there.
- If the footnote doesn't fit even alone on a fresh page, split it:
  first part on the current page, continuation on next.

Marker scheme: per-document counter; numeric by default, restart
option per page or per section.

## Done-When

- [ ] A paragraph with one footnote renders the marker in body and
      the footnote text at the page bottom.
- [ ] Footnote region is separated from body by a horizontal rule.
- [ ] Body frame shrinks to make room for footnotes.
- [ ] Long footnote splits across pages.
- [ ] Multiple footnotes on one page render in order.
- [ ] Round-trip: re-read PDF has footnotes in expected positions.
