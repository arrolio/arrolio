---
priority: P2
phase: 14
depends_on: [04, 22]
layer: color
est: 2d
status: pending
---

## Problem

Currently colours are Symbols (`:black`, `:red`) or hex strings.
Production documents need RGB, CMYK, named spot colours, and ICC
profile-based colours for accurate print reproduction.

## Approach

Files under `lib/arrolio/color/`:

- `color.rb` — base + factory: `Color.parse("black")`, `Color.rgb(255,
  128, 0)`, `Color.cmyk(0, 1, 1, 0)`, `Color.spot("PMS 200")`.

- `rgb.rb` — `RGB = Struct.new(:r, :g, :b)`. Each 0..1 Float.

- `cmyk.rb` — `CMYK = Struct.new(:c, :m, :y, :k)`.

- `spot.rb` — `Spot = Struct.new(:name, :tint)`.

- `icc.rb` — `ICC = Struct.new(:profile_ref, :components)`. Profile
  loaded from `data/arrolio/icc/*.icc`.

- `color_space_registry.rb` — registers ICC profiles; assigns
  `/ColorSpace` objects in the PDF; caches by profile path.

PDF rendering (TODO 22 extension):
- RGB → `rg`/`RG` operators.
- CMYK → `k`/`K` operators.
- Spot → separation colour space with alternate colour.
- ICC → ICCBased colour space with the embedded profile.

## Done-When

- [ ] `Color.parse("#FF8800")` returns an RGB instance.
- [ ] CMYK colour renders correctly in the PDF.
- [ ] Spot colour renders with a fallback alternate colour.
- [ ] ICC profile embedded once per document, referenced by name.
- [ ] Round-trip: re-read PDF has correct `/ColorSpace` entries.
