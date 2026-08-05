---
priority: P0
impact: high
depends_on: [70]
layer: render
status: pending
est: 3d
---

## Problem

Figures (SVG images) fail to load and render. The render log shows
`[warn] register_image failed for images/figure-N.svg: Pdfrb::Error:
no image loader matched (unknown or unrecognised format)` for every
figure in the OIML r060/1 fixture (figures 1, 2, 3, 4). Pages
reference "Figure N" captions but no figure art appears, and the
caption sits on a near-empty page.

The reference (mn2pdf/FOP) renders SVG via Apache Batik — vector
primitives preserved at full resolution. Pragmatically, we can
rasterize via `rsvg-convert` / `inkscape` / `cairosvg` as a first
step, then upgrade to vector embedding later.

## Approach

1. **External rasterizer availability check.**
   `Renderer::Pdf#register_image` should detect SVG and call out
   to an external tool:
   - `rsvg-convert` (librsvg) — fastest, most common
   - `inkscape --export-png` — fallback if rsvg-convert missing
   - `cairosvg` (Python) — last resort

   Cache the rasterized PNG in `tmp/svgraster/` keyed by SVG path
   + mtime so repeated renders don't re-rasterize.

2. **Image path resolution.** The XML references images by relative
   path (`images/figure-3.svg`). `AssetResolver.from_input_path`
   must be initialized with the XML's directory. Verify the
   pipeline passes `input_path:` through correctly. Currently
   `scripts/parity_check.rb` does pass it; CLI users may forget.

3. **Display width vs natural width.** `ImageFlowable` already
   computes display width from natural width and a max-display
   width from flow rules. Verify the max-display width matches
   the body content width (currently 106pt — should be ~450pt).

4. **Caption placement.** `FigureGroup` already emits image then
   caption. Verify the caption renders below the image with the
   right style.

5. **PDF embedding.** Once rasterized, embed as a standard image
   XObject via Pdfrb's image loader. The local pdfrb at
   `/Users/mulgogi/src/claricle/pdfrb` (v0.6.0) has PNG and JPEG
   loaders.

## Done-When

- [ ] At least one external rasterizer (`rsvg-convert` preferred)
      detected and used
- [ ] SVG images resolve against the input XML's directory
- [ ] Figures 1-4 appear in the rendered PDF
- [ ] No `[warn] register_image failed` lines in the render log
- [ ] Page 6 similarity (Figure 2 page) improves from 63% to >75%

## Expected improvement

Pages 6, 19, 20, 23 (figure pages) — estimated +5-8% overall
similarity.

## Future: vector SVG

Once rasterization works, a follow-up TODO should add direct SVG
primitive rendering (paths, text, transforms) for full vector
fidelity. That requires a separate `Renderer::SvgCanvas` adapter
that walks SVG `<path>` / `<text>` / `<g>` and emits PDF content
stream operators. Out of scope for this TODO.
