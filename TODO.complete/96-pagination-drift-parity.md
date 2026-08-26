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

## Shipped (2026-08-25): measure overflows FIXED (three coupled bugs)

1. Per-run font measurement: the KP ItemBuilder and InlineRun#width
   measured EVERY run with the paragraph's font — bold runs priced
   at regular widths, so following runs' x_offsets under-allocated
   and words OVERLAPPED ("(OIML , R)" corruption). GlyphMeasurer
   gained an optional font_name on width_of_run/string; both call
   sites pass run.style.font_name.
2. Justify SHRINK was never rendered: `extra_offset` accumulated
   only when justify was positive, so compressed lines (ratio
   > -1, legitimate TeX shrink — e.g. nat 456.5 vs measure 450.7)
   drew at natural width, past the measure. Both gates fixed
   (positive-only and the <= 0 early return in text_chunks).
3. List marker geometry now flavor config (list.geometry:
   marker_indent 18.4, marker_width 19.8, item_spacing 5.6) and
   unordered lists render the configured bullet, not the fmt-name
   autonum placeholder ("—" -> "■", x=90.7, hang 110.5/113.2).
After: ZERO words past the measure document-wide (was 20+ on p4-8).
Metric 52.52 -> 46.72 on the knife edge (correct bold widths
re-wrap every bold-bearing paragraph and reshuffle mid-document
boundaries; p16 is a pure off-by-one shift, no content loss).
Recovery rides on the density debt below.

## Open: foreword lines overflow the measure (2026-08-24)

Rendered foreword lines reach x=545 vs the body right edge 523
(+22pt into the margin; one line +94pt of text beyond the layout
measure). The LAYOUT is verified correct: TextFlowable#emit
receives width=450.7 and the standalone KP layout wraps the same
runs within it (lines <=456). Suspect a renderer-vs-layout metric
mismatch on these paragraphs (justified word positioning computed
from different measurements than the layout used). Start here:
instrument render_line_runs' cursor vs the line's placed-run
x_offsets for a foreword line.

## Shipped (2026-08-24): forced line breaks honored

Two coupled bugs fixed: Ruby's split drops trailing empty segments,
so a lone "\n" run emitted NO forced-break penalty; and the KP
dynamic program let paths skip forced breaks entirely (the parfill
glue makes the spanning single line feasible), so even correct
penalties were ignored. Result: <br>-separated spans rendered GLUED
("class A;15 degC for class B") - text corruption. All 57 breaks in
the document now produce their lines (5.6.1.2's per-class pairs
match the reference structure). The metric drops 65.29 -> 52.93 on
the page-boundary knife edge (the ~18 in-paragraph breaks add ~250pt
mid-document and reshuffle every later page); the recovery is the
remaining density debt plus the foreword's indented measure (ref
wraps foreword text narrower - an open style item).

## New finding (2026-08-24): 5.6.1.2 unitsml list inlined

The reference renders 'for load cells of class A; / 5 degC' as
stacked line PAIRS (one per class); we inline the whole set as one
flowing line ('5 degC for load cells of class A; 15 degC for...').
The unitsml values now reserve stacked height (the +digit trigger),
but the LIST STRUCTURE itself is missing - the XML's list-ish
markup around these items needs adapter investigation. Same shape
likely in 5.6.1.3 ('2 degC for load cells of class A...') and the
6.x marking lists.

## Ruled out (2026-08-24)

- Note leading: styling note bodies :note applies the style's 8pt
  paragraph margin between every body line (same trap as the
  example fix) and any line_spacing lift (1.3-1.6 swept) drops the
  metric 2-3pp. Notes are correctly spaced in aggregate.
- Figure sizing: reference figure 1's vector text spans 332pt wide
  vs our placed 337pt - figures are at the right scale (the 0.75
  sweep stands). The -324pt 2.3-to-3 continuous span is page-break
  interaction around figure 1, not missing figure height.

## Remaining 3.1 ledger (2026-08-19, fifth pass)

After the note-lists restore, 3.1's entry gaps over 15pt:
after 3.1.3.1 -25, after 3.1.3.2 -40, after 3.1.8 -69, after
3.1.10 -19. Content verified COMPLETE (the apparent missing words
in 3.1.9 were a debug-display truncation artifact - always dump
full lines before diagnosing); the deficits are small spacing
deltas (note-to-source gaps ~6pt, bullet pitch 14 vs 17).

## Fixed (2026-08-19, fourth pass)

- Nested-term definition text no longer glues into the parent: the
  raw <concept> element (refterm + renderterm + xref triple) is
  skipped in favor of <fmt-concept> (the rendered form) - term
  references now render once, with their number ("analogue-passive
  load cell (3.1.3.1)"). 'term' joined the block-level skips and
  definition paragraphs scope to the entry's own term.
- The verified drift map (labels now correct) shows: section 1
  occupies a full page for us vs 414pt in the reference (the forced
  break), 3.1.3.2/.3 spans were short from the (now fixed) missing
  content, and after-section breaks were no-ops. Section-2 region
  runs +44/+24pt per subsection (open).

## Correction (2026-08-19, third pass)

Section 3.7's per-entry pitch difference is 0pt TOTAL over all 21
entries - perfectly aligned. The earlier per-subsection span table
is UNRELIABLE: each row's span belongs to the PREVIOUS section
(off-by-one labeling), and it was measured on a scratch render.
Before fixing any more spacing, re-derive the drift map on the
current render with verified labeling (print heading + position for
both PDFs side by side). Also tested and REVERTED: a blanket
SCRIPT_LINE_FACTOR 1.4 on sub/sup-bearing lines (+2 pages overshoot
- script lines are far too numerous for blanket factors).

## Diagnostic notes (2026-08-19, second pass)

- Pages 18-20 (18-32%) are one page behind the reference from p17:
  section 3's remaining ~470pt debt (3.7 -104, 3.8 -190, 3.9 -57,
  3.5/3.6 -70 combined) pushes section 4 to a forced break a page
  late. Section 4's own span is aligned (229 vs 237pt).
- 3.8's term entry pitch is ALIGNED (88 vs 89pt) and the "[1]"
  source marker renders inline correctly (a superscript y-offset
  makes pdftotext split it into a separate row - false alarm); the
  -190pt accumulates later in the region (check its tables/notes).
- Terminology pitch overall: ours 89.4 vs ref 92.4 (~174pt total) -
  a ~3pt/entry source-line or entry-gap remainder.

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

## Shipped (2026-08-25): header parity + centered back-matter headings

- The TODO 87 `header_align_for` parity logic was unreachable: the
  builder defaulted `header_align: right` and the OIML flavor YAML
  pinned it. `nil` now means "no flavor opinion" through
  PageSequenceStart/Output::Page, and the flavor drops the pin —
  even pages get left headers (ref p4/p28 x=72.3 confirmed).
- header_offset 10.34 -> 11.68mm: header yMin 39.3 -> 35.55 (ref
  35.54). The offset ADDS to the baseline height (page_h - top +
  offset), so the earlier 10.34 was 3.8pt low.
- Preface level-1 + Bibliography headings are CENTERED (XSL
  refine_title-style: preface ancestor + level 1 -> text-align
  center) via the new flavor `title_styles: {preface_1: ...,
  bibliography_1: ...}` map — context-driven, zero core flavor
  knowledge. Foreword gap 33.4pt vs ref 33.6 ✓.
- The TODO 60 document-end marker bridge removed: markers now emit
  ONLY at paragraph reference sites (FOP semantics; unreferenced
  footnote bodies don't render). The bridge double-registered the
  footnote on the last page.
- Continuous flow re-measured: 25pp vs ref 28. Fresh drift deltas:
  3.1 -189, 3.7 -204 (tail entries), 5.3.2 -150, 5.5.1 -95,
  5.6.1.3 -134, 5.7.2.4 -134, 6.2 -119, 6.2.3 -173; 3.2/5.1.2
  run +100/+157 (we're longer there — table/figure regions to
  re-check). Note: the parity harness is TEXT-based (position
  insensitive) — geometry fixes only move it via page boundaries.

## Shipped (2026-08-25): term entry sibling spacing

FOP applies space-before BETWEEN sibling blocks: each term entry's
second+ definition paragraphs ("(For notes...)" line) and the
SOURCE line carry ~7.6pt space-before in the reference (gaps 21pt
vs our 14pt = ~10pt/entry deficit, x63 entries ~ 630pt). New
flavor config `term: {definition_paragraph_space_before: 7.6,
source_space_before: 7.5}`; the builder applies it after the first
definition paragraph and on the SOURCE flowable. Entry spans now
101pt vs ref 98 (3.1.4/.5 measured). Continuous flow 25 -> 26pp
(ref 28); forced-break render grows to 30pp (knife edge — metric
40.92% and IGNORED until debt closes; text-based harness punishes
boundary reshuffles only).

## Fresh drift map (2026-08-25, continuous, post term-spacing)

Drift is now nearly UNIFORM: -1165pt at 3.1 to -1507 at 5.7.2 —
i.e. ~1.5 pages consumed by the foreword/intro region, growing
slowly. Remaining per-region deltas:
- 5.1.2 span +419pt (WE RUN LONG): our Table 1 + Figure 4 + Table
  2 blocks consume ~598pt where the ref packs ~180pt (heading-to-
  heading, p15-16 vs p17). Needs table/figure height methodology
  (row-pitch? whole-table keep_together page moves? figure scale).
  Ref Table 1 rows pitch ~25-26pt (419/445/470) - same floor as
  ours; suspect Figure 4 image height + page-break waste.
- 3.7 span -182pt (tail entries 3.7.16-.21 still unsampled).
- 5.3.2 span -218pt (the display formula + footnote region;
  TODO 90 display-formula piece).
- 5.6.1.3 -69, 3.1 -72, 5.1.7 -116: smaller residues.
- 5.5.1 fixed (was -95, now -6); 5.6.1.3 improved (-134 -> -69).

## Shipped (2026-08-25, PR #97): table captions carry inline runs

extract_table_caption flattened via text_of — embedded stems
serialized to raw asciimath ('n_("LC")') and rendered across ~3
stacked pseudo-lines: Table 1's caption block was ~190pt vs the
reference's ~20pt (the bulk of the 5.1.2 +419pt deficit). Captions
now collect inline runs (math subscripts survive: "(nLC)" one
line). Pages 30 -> 29; parity 40.92 -> 41.82.

## Shipped (2026-08-26, PRs #99-#100): inline headers, atomic figures, keep-with-next

- Title-less numbered clauses are inline-header clauses (standoc
  inline-header): the number prefixes the first paragraph
  ('2.1 This Recommendation ...' inline) instead of consuming a
  heading line. Content::Section#heading? is now title-based.
- Figures are atomic: Flowables::FigureFlowable composes image +
  caption (keep-together) so a caption can never orphan onto the
  next page. caption_gap 28pt / block_gap 24pt from the reference.
- XSL-FO keep-with-next implemented in the engine: a heading that
  fits but whose next flowable's min_keep_height would not moves
  with it (orphaned '3.6' heading above moved Figure 3 was the
  observed defect). Heading styles set keep_with_next: true.
- The 5.3.2 'display formula' is actually an INLINE stem
  (block=false) that JEuclid gives stacked vertical extent - the
  MATH_LINE_FACTOR model already covers it. The remaining 5.3.2
  delta is footnote-zone + whole-table page-move interaction, not
  a missing display-math feature.
- Terminology preamble (VIM/VIML/D9/D11/B18 list) matches the
  reference's flowing-text shape already.
- REFERENCE NOTE: the ref breaks to a fresh page before '3
  Terminology' (p6 ends at Figure 2's caption with ~260pt
  whitespace) - a landings-matched break to apply via
  page_break_before_numbers once debt closes.

Drift after: 3.1 -1111 (was -1345), 3.6 span +242 is page-move
whitespace (atomic figure), 3.7 -93, 5.3.2 -117, 5.6.1.3 -69.
Forced-break parity 42.23 -> 44.82; continuous 26pp vs ref 28.

## LANDINGS REACHED (2026-08-26, PRs #102-#105): 28/28 pages, 65.79%

- Landings-matched breaks shipped: '3 Terminology' and '5
  Metrological' start fresh pages (the reference's only
  top-of-page section landings); each preface clause gets its own
  page (ToC p3, Foreword p4). insert_page_break_before: false.
- Example bodies: line_spacing 1.5 + 3pt item spacing (ref pitch
  19-20pt; was 13.6/no gap) - ~130pt recovered in 5.5.1.
- Lead-in paragraphs keep with following TABLES and LISTS
  (mn2pdf keep-with-next): TableFlowable#min_keep_height = caption
  + repeated header + first welded group; ListFlowable's = first
  item. Figures EXCLUDED - the ref breaks freely between text and
  figures. This reproduced the ref's page-end whitespace before
  table sections and matched the page count.
- Per-kind list geometry: ordered markers at the margin (x=72,
  hang 92), fixing 6.1/6.2 lists and nested depth.
- Part-title block space reserved (title.block_space 55pt): first
  body page matches the ref exactly (title y70, heading y130).
- Trajectory today: 44.82 -> 57.61 -> 61.34 -> 65.22 -> 65.79.

Remaining offsets (page map): section 3 (p8-16) runs ~1-3 entries
ahead per page (terms region ~15-25pt/page denser than ref);
5.1-5.7 and 6.x run ~0.3 page ahead. Both realign at the landings.
Next: per-entry comparison in 3.2-3.5 (notes/lists/tables inside
terms) and the 5.1.x table-split row pitch.

## Measurement

`bundle exec rake parity:check` — 64.07% (2026-08-17).
