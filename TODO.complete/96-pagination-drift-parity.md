---
priority: P1
impact: high
depends_on: [89, 92]
layer: layout
status: in progress
est: 3d
---

## Problem

With table geometry correct, the remaining parity gap is accumulated
pagination drift: our body text consumes slightly different vertical
space than the reference, page by page, so headings and tables land
on different pages. Whole-table moves (correct FOP semantics) turn
small drift into large whitespace gaps.

## Progress (2026-08-18, 59.12% after geometry corrections)

Fixed (all verified against the reference):
- **Body region geometry**: the body was shrunk by the before/after
  region extents — XSL-FO keeps the body at the full content
  rectangle; extents only size the header/footer strips inside the
  margins. The old geometry wasted 102pt per page and "matched" the
  reference only by accident.
- **Section levels** derive from the autonumber's dotted depth
  ("5.1.1" → 3); the fmt-title depth attribute is absent for most
  sections, so nearly every heading resolved to level 1 and its
  level-specific margins never applied.
- **Term entry spacing**: +12pt before each entry's number, +6pt
  after the preferred term (reference pitch 109.5pt vs our 87.5pt).
  Terms region now within ±0.2pg.
- **Heading margins**: heading_2 margin-bottom 20pt, heading_3 8pt
  (reference level-2/3 gaps measured 25pt vs our 17pt).
- **Header/footer offsets** calibrated to the reference (10.34mm /
  13.6mm from the body margin).

The metric moved 64.07% → 59.12% because the corrected geometry
re-flowed every page; the old alignment was built on a wrong body
position. Remaining deficits are now clean and quantified below.

## Drift map (heading absolute-position delta, 2026-08-18, 59.12%)

Measured as (our page×770 + y) − (ref page×770 + y) per heading;
page breaks reset drift to ~0, so each region is independent:

| Region | Drift | Notes |
|--------|-------|-------|
| 2.1–3.1 (intro/foreword) | +0.7..1.0pg | we consume more space (open) |
| 3.2–3.9 (terms) | ±0.2pg | ALIGNED after term spacing fix |
| 5.1–5.1.5 | ±0.05pg | aligned |
| 5.1.5→5.1.6 | −103pt | Figure 4 block shorter than reference |
| 5.3.2→5.4 | −212pt | Two FEATURE gaps, not spacing (2026-08-18): (1) the footnote in 5.3.2's second paragraph renders INLINE in our output; the reference pins its body ("1) Associated with apportionment...") to the PAGE BOTTOM via the FOP footnote area, leaving 115pt of body space free on p19. (2) the "0.3 ≤ pLC ≤ 0.8" formula renders as a centered DISPLAY line in the reference; we inline it. See TODO 60 (page-bottom footnotes) and TODO 90 (display formulas) |
| 5.5.1→5.5.2 | −125pt | Example blocks fixed (2026-08-18): "Example:" block label + 35.4pt body indent; remainder is creep/math content |
| 5.6.1→5.6.2 | −127pt | open |
| 5.7.x | −70pt | open |
| 6.x–Annex | −0.8pg | follows from above |

Beware false anchors when measuring: cross-references in body text
("see 5.1.6 and 5.1.7") match the heading regex — validate monotonic
page order before trusting a span.

## Key discovery (2026-08-19): the forced breaks are compensating

The reference flows CONTINUOUSLY - no forced section breaks in the
XSL; its fresh-page section starts (3 Terminology, 5 Metrological,
Bibliography) are natural landings. Our content under continuous
flow is only 23-25 pages vs the reference's 28: a genuine ~3-5 page
DENSITY debt that the per-section forced breaks (insert_page_break_
before/after_section: true) mask by resyncing every region.
Continuous flow scores 33%, selective breaks (3/5/Bibliography)
score 42%, forced breaks score 64.53%.

Density-debt suspects, in priority order:
1. mfrac/msqrt flattened to "/" text (TODO 90 open piece): the 3.7
   measurement/error terms contain fraction formulas the reference
   renders as tall stacked blocks (2-3 lines each); ours render one
   line. Likely 1-2 pages.
2. Line pitch: ours 13.0 vs reference 13.4 (~0.4pt/line = ~0.7pg).
3. Figures 1-4 sizing and the foreword/intro region's +0.7pg.

The builder now supports `section.page_break_before_numbers` for
landings-matched breaks once the density debt closes.

## Approach

1. Instrument per-region spacing: compare y-gaps of consecutive
   headings/paragraphs ours vs reference (re-derive with
   `pdftotext -bbox` + heading regex).
2. Terms (3.x): measured (2026-08-17) our entry pitch 87.5pt vs
   reference 109.5pt. Per entry the reference has +6pt after the
   preferred term and +12pt before the next entry's number
   (number/preferred/definition lines otherwise identical). CAUTION:
   closing this deficit is a knife edge — +6pt/entry already pushes
   section 4/5 one page later and the overall metric drops ~15pp
   (5.x/6.x misalign). The spacing must land so the region END
   matches the reference exactly; apply the full +18-22pt/entry only
   together with matching the region's non-term content (notes,
   figures 1-3 spacing).
3. Intro/foreword (2.x): we run 0.8pg longer — compare note/paragraph
   spacing on pages 5-6.
4. Figure caption spacing in 5.1.6-5.1.7 (~70pt excess).
5. Each closed gap re-aligns a table and compounds: fix regions in
   document order, re-running parity after each.

## Done-When

- [ ] Every region in the drift map within ±0.1pg
- [ ] No table whole-jump leaves >40pt whitespace where the reference
      splits or starts cleanly
- [ ] Overall parity ≥ 70%

## Measurement

`bundle exec rake parity:check` — 64.07% (2026-08-17).
