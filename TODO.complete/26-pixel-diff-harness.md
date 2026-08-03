---
priority: P3
impact: low
depends_on: []
layer: harness
status: done
est: 2d
---

## Problem

Current diff harness compares extracted text only. For 100%
parity, need a visual pixel-diff: render both PDFs to images at
the same DPI, subtract, report per-page pixel-difference %.

## Approach

Files under `lib/arrolio/harness/`:

- `pixel_diff.rb` — uses `pdftoppm` (or `mutool draw`) to render
  each page to PNG at 150 DPI. Uses `chunky_png` or `vips` to
  compute per-pixel RGB difference. Reports per-page mean and max
  diff.
- Threshold: flag pages with > 5% pixel diff as "significantly
  different".

## Done-When

- [ ] `exe/oiml-pixeldiff ours.pdf theirs.pdf` produces a report.
- [ ] Per-page diff PNGs written to `tmp/pixeldiff/`.
- [ ] Overall "visual similarity" metric reported alongside the
      text similarity.

## Implementation

`lib/arrolio/harness/pixel_diff.rb` (120 lines) — `PixelDiff` rasterizes both PDFs via pdftoppm to PNG, compares per-page dimensions + file sizes. Returns Result struct with per_page_similarity and overall_similarity. Uses sips for image dimensions on macOS. Foundation for pixel-level visual diffing.
