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

`bundle exec rake parity:check` reports **43.83%** overall
similarity on the OIML r060/1 fixture, 29 pages vs 28 reference.

Per-page summary:
- Page 1 (cover): 48.0% — needs TODO 71 (cover layout)
- Page 2 (back of cover): 100% — done
- Pages 3-4 (ToC + Foreword): 51-61% — needs TODO 73 (ToC leaders)
- Pages 5-9 (body intro + terminology): 38-65% — needs TODO 79 (KP finish)
- Pages 10-17 (definitions): 23-78% — mixed; some at 77%
- Pages 18-25 (tables + figures): 17-55% — needs TODO 72 (tables) + 74 (SVG)
- Pages 26-28 (body end): 23-55% — needs TODO 77 (formatting)
- Page 29 (bibliography overflow): 0% — pagination drift

## Critical path to 90%+ similarity

```
70 (done) → 79 (in progress) → 72 → 74 → 71 → 73 → 77 → 78
```

After these land, remaining gaps are <2% each (sub/sup, MathML,
page templates).

## Status snapshot

| TODO | Status | Layer | Impact |
|------|--------|-------|--------|
| 70 (TTF metrics) | done | metrics | critical |
| 80 (parity CI) | done | harness | critical |
| 79 (KP finish) | in progress | text | high |
| 78 (bibliography) | pending | adapter | med |
| 77 (text formatting) | pending | render | med |
| 76 (page templates) | pending | engine | med |
| 75 (MathML) | pending | flowable | low |
| 74 (SVG figures) | pending | flowable | high |
| 73 (ToC leaders) | pending | flowable | med |
| 72 (table layout) | pending | flowable | high |
| 71 (cover layout) | pending | flowable | high |
| 66 (semantic types) | in progress | content | med |
| 63 (purge hardcoded vocab) | pending | adapter | med |
| 62 (font resolution strict) | pending | font | low |
| 61 (error model) | pending | error | low |
| 60 (footnote inline) | blocked | adapter | med |

## Verification

After each TODO: `bundle exec rake` (rspec + rubocop) must be green,
and `bundle exec rake parity:check` similarity must not regress.
