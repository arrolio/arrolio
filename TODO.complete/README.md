# TODO.complete — Path to 100% mn2pdf parity

This directory tracks every piece of work needed to make Arroolio's
OIML output byte-equivalent (visually + textually) to mn2pdf's
output for the same input XML.

The reference rendering is `mn2pdf v2.55` (Java), invoked via
Metanorma. Reference PDF for r060/1 lives at
`~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.pdf`
(28 pages, 744 KB, fonts: FuturaPT-Book/Demi/Light,
TimesNewRomanPSMT family, Cambria Math).

The authoritative style reference is
`~/src/mn/metanorma-taste/data/oiml/oiml.xsl` (767 lines).

## Front matter shape (every file)

```yaml
---
priority: P0     # P0 = blocks parity; P1 = important; P2 = polish; P3 = future
impact: high     # high = >5% similarity swing; med = 1-5%; low = <1%
depends_on: []   # TODO numbers
layer: foundation | metrics | text | flowable | engine | output | render | adapter | harness
status: pending  # pending | in_progress | done
est: 1d          # 1d = single focused session; 5d = multi-week module
---
```

## Status legend

- `pending` — not started
- `in_progress` — actively being worked
- `done` — complete, specs pass, ready for review
- `deferred` — intentionally out of scope for this milestone

## Current parity baseline (2026-08-05)

`bundle exec rake parity:check` reports **48.12%** overall
similarity on the OIML r060/1 fixture, 29 pages vs 28 reference.

Per-page summary:
- Page 1 (cover): 48.0% — needs TODO 71 (PositionedBlock shipped;
  full cover rebuild pending).
- Page 2 (back of cover): 100% — done.
- Pages 3-4 (ToC + Foreword): 51-86% — TODO 73 page-number
  right-align shipped; bold + indent shipped.
- Pages 5-9 (body intro + terminology): 38-79% — KP improvements
  landed; some drift.
- Pages 10-17 (definitions): 37-88% — mixed; terminology compactness.
- Pages 18-25 (tables + figures): 18-65% — TODO 72 header-bold +
  colspan shipped; needs continuation caption and rowspan.
- Pages 26-28 (body end + bibliography): 5-30% — TODO 78
  bibliography-as-paragraph shipped.
- Page 29 (extra): 0% — pagination drift.

## Critical path to 90%+ similarity

```
70 (done) → 79 (in progress) → 72 → 74 → 71 → 73 → 77 → 78
```

After these land, remaining gaps are <2% each (MathML fractions,
page templates, hyperlink underline).

## Status snapshot

| TODO | Status | Layer | Impact |
|------|--------|-------|--------|
| 60 (footnote fidelity) | done | adapter | med |
| 61 (strict mode) | done | engine | high |
| 66 (semantic types) | done | content | high |
| 70 (TTF metrics) | done | metrics | critical |
| 71 (cover layout) | in progress | flowable | high |
| 72 (table layout) | in progress | flowable | high |
| 73 (ToC leaders) | done | flowable | med |
| 74 (SVG figures) | in progress | render | high |
| 75 (MathML) | in progress | flowable | med |
| 76 (page templates) | in progress (header align) | engine | med |
| 77 (text formatting) | done | adapter | low |
| 78 (bibliography) | in progress (text shown, hanging indent pending) | adapter | low |
| 79 (line breaking) | in progress | text | high |
| 80 (parity CI) | done | harness | critical |

## Verification

After each TODO: `bundle exec rake` (rspec + rubocop) must be green,
and `bundle exec rake parity:check` similarity must not regress.
