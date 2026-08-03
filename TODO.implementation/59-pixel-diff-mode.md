---
priority: P1
phase: 17
depends_on: [55, 57]
layer: harness
est: 2d
status: pending
---

## Problem

The semantic comparator (TODO 55) catches missing words and
structural changes. But some visual regressions slip through — a
missing table border, a 0.5pt colour shift, an anti-aliasing change.
Pixel diff rasterises both PDFs and compares images, catching
anything semantic diff misses.

Pixel diff is one **mode** within the harness, not the whole diff
strategy. It's expensive (~1s/page at 150 DPI; ~10s/page at 300 DPI)
so it's opt-in via profile, not on by default.

## Approach

Files under `lib/arrolio/harness/pixel/`:

- `rasteriser.rb` — wraps `pdftoppm` (poppler) to convert a PDF to a
  PNG per page at configurable DPI. Falls back gracefully if
  `pdftoppm` isn't installed.

- `image_comparator.rb` — uses ImageMagick `compare` to compute a
  per-page diff image and a similarity metric (0..1). Optionally
  uses libvips for faster batch comparison.

- `pixel_diff_report.rb` — value object: `per_page_similarity`
  (Array of Float), `overall_similarity` (Float),
  `diff_image_paths` (Array of paths to per-page diff PNGs).

- `pixel_dimension.rb` — bridges into the comparator subsystem: a
  `:pixel` dimension that contributes a `DiffNode` when similarity
  drops below threshold (default 0.98 per page).

- `html_embedder.rb` — when the HTML formatter (TODO 56) runs,
  embeds the per-page diff images as base64 PNGs in the report.

### Pipeline integration

Pixel diff plugs into the comparator (TODO 55) as one more dimension:

```ruby
comparator = Comparator::PdfComparator.new(
  profile: :visual_strict
)
# profile: :visual_strict includes :pixel dimension
```

### Heuristic thresholds

- 1.0 similarity → identical; no diff.
- ≥ 0.99 → informative (anti-aliasing noise).
- 0.95..0.99 → flagged; usually a real but minor visual change.
- < 0.95 → normative; almost certainly a visible regression.

### CLI

```sh
# Run pixel diff alone
arrolio-harness pixel-diff ours.pdf ref.pdf --dpi=150

# Combined semantic + pixel diff
arrolio-harness diff ours.pdf ref.pdf --profile=visual_strict
```

### CI integration

- Rake task `rake harness:pixel_diff[fixture]` — runs against one
  fixture.
- Rake task `rake harness:pixel_diff_all` — runs against every
  fixture; uploads the HTML report as a CI artifact.
- Weekly CI job (not per-commit) due to runtime cost.

## Done-When

- [ ] Two identical PDFs produce overall similarity 1.0.
- [ ] Two PDFs with one word different produce overall similarity
      > 0.99 with a visible diff blob in the report.
- [ ] Two PDFs with a colour change produce overall similarity >
      0.95 with the changed region highlighted.
- [ ] HTML report renders in a browser; diff images embedded as
      base64.
- [ ] The `:pixel` dimension integrates cleanly with the comparator.
- [ ] If `pdftoppm`/ImageMagick isn't installed, the dimension
      skips cleanly with a warning (no crash).
- [ ] Profile `:visual_strict` includes pixel diff; `:strict` doesn't.
