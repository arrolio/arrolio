---
priority: P1
impact: critical
depends_on: []
layer: render
status: done
est: 1d
---

## Problem

Figures in the standoc presentation XML contain inline `<svg>` elements
inside `<image>` tags. The adapter was only looking for external image
file references (`images/figure-1.svg`) which don't exist, causing all
4 figures to be missing from the output — the biggest source of
pagination drift.

## Fix (2026-08-09)

### Adapter (`extract_figure_image`)

When a `<figure>` has an `<image>` element:
1. Search recursively for `<svg>` inside the image element
2. If found, serialize the SVG XML and extract viewBox dimensions
3. Store as `Content::Image` with `inline-svg:` prefix

When no `<image>` element exists, search recursively in the figure for
standalone `<svg>`.

### Flow builder (`image_flowable`)

Recognize the `inline-svg:` prefix:
1. Extract SVG XML from the prefixed source string
2. Write to a temp `.svg` file
3. Pass to `ImageFlowable` which delegates to the renderer

### Renderer (existing)

The renderer already rasterizes `.svg` files via `rsvg-convert` to PNG
and caches the result. No renderer changes needed.

### Config (`flow_rules.yml`)

Set `max_display_width: 450` (was default 106) to allow full-width
figure rendering.

## Impact

Parity: 53.53% → **56.98%** (+3.45%)
Page count: 26 → **27** (reference 28)

| Page | Before | After |
|------|--------|-------|
| 5 | 94.1% | 99.6% |
| 9 | 35.7% | 87.4% |
| 12 | 37.4% | 64.0% |
| 14 | 45.8% | 79.5% |

## Done-When

- [x] Inline SVG extracted from `<image>` elements
- [x] viewBox dimensions used for aspect ratio
- [x] rsvg-convert rasterizes SVG to PNG
- [x] Figures appear in output at correct size
- [x] Parity improved by 3.45%

## Measurement

`bundle exec rake parity:check` — 56.98%.
Last measured: 2026-08-09.
