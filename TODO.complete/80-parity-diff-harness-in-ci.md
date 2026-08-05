---
priority: P0
impact: critical
depends_on: [70]
layer: harness
status: done
est: 1d
completion_date: 2026-08-05
---

## Problem

Throughout development, "28 pages, matches the reference" was claimed
without ever running the PDF diff. The diff harness existed
(`Harness::PdfDiff`) but was not integrated into the development loop
or CI, and the script that called it had a unit bug that disguised
the actual parity number.

## Approach (delivered)

1. **`rake parity:check`** renders the OIML r060/1 fixture through
   the generic pipeline and diffs it against the reference PDF,
   printing per-page similarity and an overall score.

2. **Unit-correct reporting.** `PdfDiff#similarity` is a Float in
   [0, 1]; the script now multiplies by 100 for display and
   compares against fractional thresholds (0.5 / 0.1) rather than
   the previous buggy > 50 / > 10 integer checks.

3. **`scripts/parity_check.rb` invokes `ParityCheck.run`** at the
   bottom (previously the module was defined but never invoked —
   the script exited silently with no output).

4. **`ConfigDrivenPipeline` resolves fonts via FontScanner** so
   the rendered PDF embeds the actual Jost/Times fonts the
   reference uses, making the diff meaningful instead of comparing
   against system fallbacks.

## Done-When

- [x] `rake parity:check` renders + diffs + prints per-page report
- [x] Reporting shows percentages in [0, 100] not [0, 1]
- [x] Script invokes the diff (no silent exit)
- [x] Fonts are embedded in the rendered PDF, so the diff is
      meaningful

## Verification

```
$ bundle exec rake parity:check
Overall similarity: 24.58%
Our pages: 30, Reference pages: 28

  Page 1: 48.0% [PARTIAL]
  Page 2: 100.0% [OK]
  ...
```

## Not Yet Done

- `spec/arrolio/parity_spec.rb` regression spec — the next parity
  PR should add this with a floor threshold (start at 20%, raise
  as TODOs land). The spec belongs in the gem'sRSpec suite so CI
  fails on regressions.

- GitHub Actions wiring — the spec runs locally via `bundle exec
  rspec`; CI invocation is added in the workflow file (`.github/
  workflows/*.yml`) by the release engineer.
