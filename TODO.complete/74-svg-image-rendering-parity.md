---
priority: P1
impact: med
depends_on: [70]
layer: render
status: pending
est: 3d
---

## Problem

Figures (SVG images) fail to load and render. The render log shows
"register_image failed for images/figure-3.svg: Pdfrb::Error: no
image loader matched". Multiple pages reference figures ("Figure 1",
"Figure 2", "Figure 4") that don't appear in our output.

The reference renders these as embedded images (rasterized or vector).

## Approach

1. **SVG rasterization**: `Renderer::Pdf#resolve_image_for_pdfrb`
   already attempts to rasterize SVG via `rsvg-convert`, but the
   command may not be installed or the image paths may not resolve.
   Verify `rsvg-convert` is available; fall back to `inkscape` or
   `cairosvg` if not.
2. **Image path resolution**: the XML references images by relative
   path (e.g., `images/figure-3.svg`). The `AssetResolver` must
   resolve these against the input XML's directory. Verify the
   resolver is being given the correct base directories.
3. **Image positioning**: images should be centered or left-aligned
   within the body frame, with the figure caption below. The current
   `ImageFlowable` handles this, but the display width calculation
   may not match the reference.
4. **PDF embedding**: if the reference embeds vector SVG (not
   rasterized), we need to either convert SVG to PDF XObjects or
   render SVG primitives directly on the canvas. This is a larger
   task; rasterization is the pragmatic first step.

## Expected improvement

Fixes pages 6, 8, 19 where figures are missing. Estimated 5%
similarity improvement.

## Done-When

- [ ] `rsvg-convert` (or equivalent) is invoked successfully
- [ ] SVG images resolve against the input XML's directory
- [ ] Figures appear on the correct pages with captions
- [ ] No "register_image failed" warnings in the render log
