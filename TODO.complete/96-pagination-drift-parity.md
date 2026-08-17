---
priority: P1
impact: high
depends_on: [89, 92]
layer: layout
status: pending
est: 3d
---

## Problem

With table geometry correct, the remaining parity gap is accumulated
pagination drift: our body text consumes slightly different vertical
space than the reference, page by page, so headings and tables land
on different pages. Whole-table moves (correct FOP semantics) turn
small drift into large whitespace gaps.

## Drift map (heading absolute-position delta, 2026-08-17, 64.07%)

Measured as (our page×770 + y) − (ref page×770 + y) per heading;
page breaks reset drift to ~0, so each region is independent:

| Region | Drift | Notes |
|--------|-------|-------|
| 2.1–2.3 (intro/foreword) | +0.8pg | we consume more space |
| 3.1–3.1.3 (terms start) | +1.0pg | recovers to +0.28 by 3.1.4 |
| 3.4 | ~0 | aligned |
| 3.5–3.9 (terms) | −1.9pg | we are far DENSER (term spacing) |
| 5.1–5.3.2 | +0.05pg | aligned after section page break |
| 5.3.2→5.4 | +0.76pg | Table 3/4 region: whole-table gaps |
| 5.7.2.5→6.1 | +1.4pg | Table 5/6 region: accumulated |
| 6.x–Annex | +1.1–1.4pg | follows from above |

## Approach

1. Instrument per-region spacing: compare y-gaps of consecutive
   headings/paragraphs ours vs reference (the drift map generator
   lives in this TODO's history — re-derive with
   `pdftotext -bbox` + heading regex).
2. Terms (3.x): our term entries are ~30% denser than FOP — compare
   term-entry spacing (number/name/definition/source margins) with
   the XSL term styles.
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
