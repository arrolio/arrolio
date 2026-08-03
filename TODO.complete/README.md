# TODO.complete — Path to 100% mn2pdf parity

This directory tracks every piece of work needed to make Arrolio's
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

## Critical path to 90%+ similarity

```
01 → 02 → 04 → 05 → 06 → 07 → 09 → 11 → 14 → 18 → 22
```

After 22 lands, every remaining TODO is a polish item.

## Status legend

- `pending` — not started
- `in_progress` — actively being worked
- `done` — complete, specs pass, ready for review
- `deferred` — intentionally out of scope for this milestone

## Verification

After each TODO: `bundle exec rake` (rspec + rubocop) must be green,
and `bundle exec ruby exe/oiml-diff out.pdf <reference>` similarity
must not regress.
