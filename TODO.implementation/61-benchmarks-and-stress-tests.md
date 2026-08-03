---
priority: P3
phase: 18
depends_on: [54]
layer: polish
est: 2d
status: pending
---

## Problem

Need performance baselines to detect regressions and find hot paths.
Also need to know Arrolio's behaviour on stress cases (very long
documents, deep tables, thousands of paragraphs) before claiming
production-ready.

## Approach

Files:

- `benchmarks/bench.rb` — runs against a generated test document
  (10, 50, 200 pages) and reports wall-clock per phase:
  - Content tree construction.
  - LayoutSpec construction.
  - Flowable list construction.
  - Engine::Paged layout.
  - Renderer::Pdf render.
  - Total.
- Compares against `HexaPDF` (if installed) and FOP (if installed)
  on the equivalent source.

- `spec/arrolio/stress_spec.rb` — tagged `:stress`:
  - 1000-page document lays out without crash.
  - Memory after layout is < 500 MB.
  - A 100-row table lays out across 5+ pages.
  - A 100-item list lays out correctly.
  - A document with 100 inline runs per paragraph lays out correctly.

- Profiling: `stackprof` integration; `rake bench:profile` produces
  a flamegraph.

## Done-When

- [ ] `rake bench` runs and prints per-phase timings.
- [ ] A 100-page OIML-style document renders in < 30 seconds.
- [ ] Memory stays bounded: 1000-page doc uses < 500 MB.
- [ ] Hot paths identified; obvious inefficiencies fixed.
- [ ] Stress specs pass under default RSpec config (not just `:stress`).
- [ ] Benchmark history tracked in `benchmarks/history.csv` so
      regressions are visible across commits.
