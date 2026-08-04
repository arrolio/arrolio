---
priority: P0
impact: critical
depends_on: [70, 71, 72, 73, 74, 75, 76, 77, 78, 79]
layer: harness
status: pending
est: 1d
---

## Problem

Throughout development, "28 pages, matches the reference" was claimed
without ever running the PDF diff. The diff harness exists
(`Arroolio::Harness::PdfDiff`) but was never integrated into the
development loop or CI.

## Approach

1. **Add a `rake parity:check` task** that renders the OIML r060/1
   fixture through the generic pipeline and diffs it against the
   reference PDF, printing per-page similarity and overall score.
2. **Add a parity regression spec** (`spec/arrolio/parity_spec.rb`)
   that renders the fixture and asserts overall similarity ≥ a
   configurable threshold (starting at 0.5%, raised as each TODO
   lands).
3. **Fail CI when parity regresses**: the spec must not pass if
   similarity drops below the threshold.

## Done-When

- [ ] `rake parity:check` renders + diffs + prints per-page report
- [ ] `spec/arrolio/parity_spec.rb` asserts similarity ≥ threshold
- [ ] CI runs the parity spec on every PR
- [ ] No future claim of "matches the reference" is made without
      running `rake parity:check` first

## Verification

```bash
$ rake parity:check
Overall similarity: X.XX%
Page 1: ...
Page 2: ...
...
```
