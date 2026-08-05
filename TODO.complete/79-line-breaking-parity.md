---
priority: P2
impact: high
depends_on: [70]
layer: text
status: in_progress
est: 3d
---

## Problem

FOP uses Knuth-Plass optimal fitting; line breaks can differ from
our greedy breaker, causing text to wrap differently and content
to shift between pages.

The Knuth-Plass breaker (`TextLayout::KnuthPlass`) is enabled in
the OIML body style (`layout_spec.yml`). Until 2026-08-05 it was
badly broken — produced per-word lines because:

1. **Badness formula only counted overfull (negative ratio) lines.**
   Underfull (positive ratio) lines had `badness = 0`, so the
   algorithm had no signal to avoid them. Fixed: `badness` is now
   `100 * |ratio|^3` clamped to 10_000, matching standard
   Knuth-Plass.

2. **TOLERANCE was 100.0**, allowing `|ratio|` up to 100 (i.e.
   very stretched or shrunk lines were considered feasible).
   Standard TeX tolerance (200) corresponds to `|ratio| <= 1.26`.
   Fixed: TOLERANCE = 4.0 (allows generous stretching but rejects
   pathological lines).

3. **`build_placed_runs` skipped Glue items entirely** — every
   space between words was dropped from the output. Fixed: Glue
   items now emit `InlineRun(' ')`.

4. **`total_stretch`/`total_shrink` summed across the entire
   document**, not the current line. Renamed to
   `line_stretch(start, stop)` / `line_shrink(start, stop)`,
   scoped to the current line's item range.

5. **`Arroolio::Style::Definition` typo** in breaker.rb
   (`Arroolio` → `Arroolio`). Fixed.

## Status

KP now produces proper multi-word lines that match greedy breaker
output on simple paragraphs. Body text on pages 4-7 of the OIML
fixture renders correctly.

Remaining gap to FOP:

- Slight overfill on some lines (~10pt past target width) — KP
  picks overfull lines when the alternative (very underfull) has
  higher demerits. FOP may weight these differently.
- No hyphenation: long words at line boundaries get pushed to the
  next line, leaving the previous line underfull.
- No consecutive-flag penalty enforcement: flagged breaks
  (hyphens) next to each other aren't penalised correctly.

## Approach

1. **Tune demerits to match FOP.** FOP uses Knuth-Plass with
   specific constants. Compare our line break choices against the
   reference PDF on >20 body paragraphs; tune
   `FLAGGED_PENALTY`, `DEMERITS_LAST_LINE`, and the badness clamp.

2. **Add hyphenation.** Use `text-hyphen` or `ruby-hyphen` gem
   (or a TeX pattern data file) to compute break opportunities
   within words. ItemBuilder should emit `Box + Penalty(flagged)`
   at each valid hyphenation point. This matches FOP/TeX behavior.

3. **Handle underfull last line.** The last line of a paragraph
   should be left-aligned (not justified) — currently it gets
   justified, stretching short last lines across the full width.
   Fix in `Line#justified?` or `TextFlowable#emit`.

## Done-When

- [x] Knuth-Plass is the default line breaker for body text
- [x] Badness formula is correct for positive and negative ratios
- [x] KP produces multi-word lines (no per-word regression)
- [ ] Line break positions match FOP on >80% of body paragraphs
- [ ] Hyphenation is supported for long words at line boundaries
- [ ] Last line of a justified paragraph is left-aligned
- [ ] Overall similarity > 60% on OIML r060/1 fixture

## Measurement

`bundle exec rake parity:check` — current baseline 24.58%
overall, 30 pages vs 28 reference. Pages 4-7 OK (55-65%);
pages 8-17 LOW (5-15%); pages 18-28 PARTIAL (10-55%).

Last measured: 2026-08-05.
