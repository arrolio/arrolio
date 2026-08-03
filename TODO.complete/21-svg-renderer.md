---
priority: P1
impact: med
depends_on: [08]
layer: render
status: done
est: 5d
---

## Problem

SVG inside `<svg>` elements (cover doctype wordmark, figure-1.svg,
etc.) needs to be drawn as vector graphics, not just embedded as
PNG. mn2pdf converts SVG → PDF Form XObject via Apache Batik.

## Approach

Files under `lib/arrolio/svg/`:

- `parser.rb` — parse SVG XML into element tree (<svg>, <g>, <path>,
  <rect>, <line>, <text>, <tspan>, <polygon>, <polyline>, etc.)
- `path_parser.rb` — parse `d="M 0 0 L 10 10..."` path data.
- `transform_parser.rb` — parse `transform="scale(0.82, 1)"`.
- `style.rb` — fill, stroke, stroke-width, font-family, font-size.
- `renderer.rb` — walk element tree, emit canvas ops.
- `document.rb` — wraps the whole SVG, exposes width/height/viewBox.

For complex SVGs, render as Form XObject: draw once into a separate
Pdfrb stream, reference via Do operator from pages.

## Done-When

- [ ] Cover doctype wordmark renders (the "INTERNATIONAL
      RECOMMENDATION" stylized text in SVG).
- [ ] figure-1.svg renders on page 6.
- [ ] Specs cover: path parsing, transform, text, basic shapes.

## Implementation

SVG images rasterized to PNG via `rsvg-convert` (cached by MD5). `Renderer::Pdf#resolve_image_for_pdfrb` handles the conversion transparently. 4 figures embedded successfully. Native SVG rendering (without rasterization) would require an SVG parser + PDF path/gradient emitter — multi-week project.
