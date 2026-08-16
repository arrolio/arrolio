---
priority: P1
impact: high
depends_on: [71]
layer: engine
status: done
est: 2d
---

## Problem

The document title block ("Part 1 - Metrological and technical
requirements") is rendered as BODY flow content, consuming ~58pt of
body region space on page 5. The reference (mn2pdf/FOP) renders it
in the HEADER area above the body region, getting it "for free".

## Evidence

Reference page 5:
- Title at y=71-95 (ABOVE body region)
- "1 Introduction" at y=130 (body region start)

Our page 5:
- Title at y=126-144 (INSIDE body region)
- "1 Introduction" at y=183 (pushed down by title)

Net effect: our page 5 has ~58pt less content than reference. Over
the document, this accumulates to ~1 page of offset.

## Approach

1. **Static content per page sequence.** The PageSequenceStart
   flowable should support a `title_template` that renders in the
   header region on the first page of the sequence.

2. **Renderer support.** The renderer draws the title at a fixed
   position in the header area (y = margin_top to body_top) when the
   page is the first of a sequence with a title template.

3. **Flow builder change.** `append_title_block` should NOT emit a
   body TextFlowable. Instead, pass the title to the
   PageSequenceStart flowable.

## Done-When

- [ ] Title renders above body region (y < 126 on A4 with 26.5mm/18mm)
- [ ] Body content starts at same y as reference (y=130 for heading)
- [ ] Page 5 contains Introduction + section 2 content (matching ref)
- [ ] Overall parity > 65%

## Measurement

`bundle exec rake parity:check` — currently 62.7%. Page 5: 99.6%,
page 6: 66.7%, page 7: 50.0% (mostly empty due to figure push).
Last measured: 2026-08-16.
