---
priority: P0
impact: high
depends_on: []
layer: metrics
status: done
est: 2d
---

## Problem

Arrolio measures text using PDF's 14 standard Type1 fonts
(Times-Roman, Helvetica, Courier). mn2pdf embeds TimesNewRomanPSMT,
FuturaPT-Book, Cambria Math — different glyph widths. Letter width
drift of 1–3% accumulates across a 28-page document into ~3 pages of
pagination shift, breaking page-by-page text diffing.

## Approach

Files under `lib/arrolio/font_metrics/`:

- `true_type_metrics.rb` — reads TTF/OTF + collects head, hhea,
  hmtx, cmap, OS/2 tables via `Pdfrb::Font::TrueType::File` (already
  exists in pdfrb). Provides the same interface as `AfmMetrics`:
  `units_per_em`, `advance_width(char)`, `width_of_string(str, font_size:)`,
  `ascender`, `descender`, `cap_height`, `x_height`, `line_height`.
- Update `Registry#[]` to consult registered TTF paths first, then
  fall back to AfmMetrics for the 14 standards.
- Add `Registry.register_ttf(name, path)` (currently a no-op stub
  in pdfrb/layout — port and own it here).

## Vendor fonts

The Metanorma OIML package ships:
- TimesNewRomanPSMT.tff and variants (Bold, Italic, BoldItalic)
- FuturaPT-Book.ttf, FuturaPT-Demi.ttf, FuturaPT-Light.ttf
- Cambria Math

Vendored location TBD — locate via
`find ~/src/mn -name "TimesNewRoman*.ttf"` and add to `data/fonts/`
or document a `OIML_FONTS_DIR` env var.

## Done-When

- [ ] `TrueTypeMetrics` reads any TTF and returns same-shape results
      as `AfmMetrics`.
- [ ] `Registry.register_ttf("Times New Roman", path)` then
      `Registry["Times New Roman"]` returns a `TrueTypeMetrics`.
- [ ] Specs cover: standard lookup, TTF override, fallback to AFM,
      case-insensitive name matching, font-style variant selection.
- [ ] `exe/oiml-diff` similarity improves by ≥5 percentage points
      across the body pages.

## Implementation

`lib/arrolio/font_metrics/true_type_metrics.rb` — reads TTF via Fontisan (head, hhea, hmtx, cmap, OS/2). `Registry.register_ttf` / `register_ttf_all` wired into pipeline.
