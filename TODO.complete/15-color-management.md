---
priority: P2
impact: low
depends_on: []
layer: render
status: done
est: 2d
---

## Problem

Color values in XML are like `rgb(34,30,31)` or `#5c6770`. Arrolio
parses some but doesn't emit ICC-based color spaces. mn2pdf uses
sRGB ICC profile for accurate cross-renderer color.

## Approach

Files:

- Update `Renderer::Pdf#parse_color` to handle `rgb(r,g,b)`.
- Add ICC profile sRGB embedded as OutputIntent on the catalog.
- `OutputIntent` references the ICC stream; subsequent fill/stroke
  operators can declare /ICCBased color space.

## Done-When

- [ ] All `rgb(...)` colors parse.
- [ ] PDF has an /OutputIntents entry with /S /GTS_PDFA1.
- [ ] Specs cover: rgb parse, hex parse, named colors, ICC stream.

## Implementation

`lib/arrolio/color.rb` (110 lines) — `Color` value object. Parses #RGB, #RRGGBB, rgb(r,g,b), rgb(r%,g%,b%), 16 named colors. `to_render` returns [:rgb, r, g, b] or grayscale float. BT.601 luminance for grayscale conversion. `Renderer::Pdf#parse_color` delegates to Color.parse. 15 specs.
