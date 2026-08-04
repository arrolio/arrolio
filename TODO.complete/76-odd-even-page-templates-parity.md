---
priority: P1
impact: med
depends_on: [70]
layer: engine
status: pending
est: 3d
---

## Problem

The reference uses odd/even page alternation:
- Odd pages: header right-aligned, footer center-aligned
- Even pages: header left-aligned, footer center-aligned
- Page numbering starts at specific values per page-sequence
  (preface starts at 3, body at 5)

Currently the engine uses a single page template for all pages and
doesn't alternate headers. The `initial_page_number` from
`PageSequenceStart` is stored but not applied to the PDF page
number.

## Approach

1. **`PageSequenceMaster` support**: `LayoutSpec` should carry
   odd/even page templates. The engine's `open_page` method should
   select the template based on the current page's parity.
2. **Initial page number**: when a `PageSequenceStart` carries
   `initial_page_number`, the engine resets the page counter. The
   renderer must emit this as the PDF page's `/PageLabel` or as the
   starting number for page-number text in headers/footers.
3. **Force page count**: the XSL specifies
   `force-page-count="end-on-even"` on some sequences, meaning the
   sequence ends on an even page (inserting a blank page if needed).
4. **Header content per parity**: the header text may differ between
   odd and even pages (e.g., even pages show the annex number,
   odd pages show the docidentifier).

## Expected improvement

Fixes header/footer alignment on every page. Estimated 3%
similarity improvement.

## Done-When

- [ ] Odd pages have right-aligned headers
- [ ] Even pages have left-aligned headers
- [ ] Page numbers start at the correct value per page sequence
- [ ] Blank pages inserted to satisfy force-page-count
- [ ] Header text alternates correctly
