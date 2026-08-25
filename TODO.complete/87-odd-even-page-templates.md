---
priority: P2
impact: medium
depends_on: [76]
layer: render
status: pending
est: 1d
---

## Problem

The OIML reference PDF uses distinct page templates for odd vs even
pages:
- Odd pages: header right-aligned
- Even pages: header left-aligned (or centered when title_complementary
  is present)

Our engine produces correct page-count parity but doesn't apply
distinct templates based on page number. The header alignment shifts
but the underlying template (margins, region extents) is the same.

## Current state

- `header_align_for(page_number)` in `Engine::Paged` returns `:left`
  for even, `:right` for odd — SHIPPED and now REACHABLE
  (2026-08-25): a nil `header_align` flows through
  PageSequenceStart/Output::Page as "no flavor opinion"; the builder
  no longer defaults to :right, and the OIML flavor dropped its
  explicit `header_align: right` pins. Explicit values still win.
- Page templates: single `body` template, no odd/even variants.

## Approach

1. **Add odd/even template variants to LayoutSpec.** Each
   `page_template` entry can specify `odd` and `even` sub-templates
   with different margins, headers, footers.

2. **Wire PageSequenceMaster.** The XSL uses
   `<xsl:conditional-page-master-reference>` with
   `odd-or-even` condition. Map this to the engine's page-open logic.

3. **Apply template per page.** `Engine::Paged#open_page` should
   select the template based on `page_number.odd?` / `page_number.even?`.

## Done-When

- [ ] Odd and even pages use different templates when configured
- [ ] Header alignment matches reference on all pages
- [ ] Blank pages inserted for even-page chapter starts
- [ ] Specs cover odd/even template selection

## Measurement

Minor visual impact; mostly affects header position consistency.
Last measured: 2026-08-08.
