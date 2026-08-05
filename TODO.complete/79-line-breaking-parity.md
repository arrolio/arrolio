---
priority: P2
impact: high
depends_on: [70]
layer: text
status: in_progress
est: 3d
---

## Problem

FOP uses Knuth-Plass optimal fitting. The original Arroolio KP
implementation had multiple bugs producing per-word lines and
overfills. As of 2026-08-06, the major issues are fixed:

## Status (2026-08-06)

Fixed bugs:
- [x] **Badness formula only counted negative ratios.** Now uses
      `100 * |ratio|^3` clamped to 10_000 for both directions.
- [x] **TOLERANCE was 100.0.** Now 2.5, rejecting pathological
      overfills.
- [x] **`build_placed_runs` skipped Glue items entirely** — every
      space between words was dropped. Now emits `InlineRun(' ')`
      per Glue.
- [x] **`total_stretch`/`total_shrink` summed the entire document.**
      Renamed to `line_stretch(start, stop)` / `line_shrink(start, stop)`,
      scoped to the current line.
- [x] **`Arroolio::Style::Definition` typo** (double-o). Fixed.
- [x] **Emergency stretch glue at the end was rendering as trailing
      space.** build_placed_runs now skips Glue items with infinite
      stretch.
- [x] **Each Glue became its own Tj block**, confusing pdftotext
      into dropping spaces between words ("durabilityerror"). Now
      Box+Glue items merge into a single placed_run per group.

Remaining gaps:
- **Hyphenation** — long words at line boundaries get pushed to
  the next line, leaving the previous line underfull. Needs TeX
  hyphenation patterns (external dependency).
- **Slight overfill on dense paragraphs** — KP picks overfull lines
  when the alternative has higher demerits. Acceptable but not
  pixel-perfect.
- **Consecutive-flag penalty** — flagged breaks (hyphens) next to
  each other aren't penalised correctly.

## Approach

1. **Tune demerits to match FOP.** FOP uses Knuth-Plass with
   specific constants. Compare our line break choices against the
   reference PDF on >20 body paragraphs.

2. **Add hyphenation.** Use `text-hyphen` or `ruby-hyphen` gem
   (or a TeX pattern data file) to compute break opportunities
   within words. ItemBuilder should emit `Box + Penalty(flagged)`
   at each valid hyphenation point. This matches FOP/TeX behavior.

3. **Handle underfull last line.** Last line of a justified
   paragraph is left-aligned (already done in renderer).

## Done-When

- [x] Knuth-Plass is the default line breaker for body text
- [x] Badness formula is correct for positive and negative ratios
- [x] KP produces multi-word lines (no per-word regression)
- [x] Spaces between words are preserved in extracted text
- [x] Last line of a justified paragraph is left-aligned
- [x] Emergency stretch glue doesn't render as trailing space
- [ ] Line break positions match FOP on >80% of body paragraphs
- [ ] Hyphenation is supported for long words at line boundaries
- [ ] Overall similarity > 60% on OIML r060/1 fixture

## Measurement

`bundle exec rake parity:check` — current baseline 47.88%
overall, 30 pages vs 28 reference. Body pages 5-15 mostly OK
(55-87%); table pages 18-25 LOW (5-35%) due to TODO 72 work
still in progress.

Last measured: 2026-08-06.
