---
priority: P0
phase: 2
depends_on: [06]
layer: metrics
est: 1d
status: in_progress
---

## Problem

Layout callers ask "how wide is this Unicode string at this size?"
The AFM gives glyph widths by AdobeStandardEncoding code or glyph
name, not Unicode codepoint. We need Unicode → AFM resolution via
the Adobe Glyph List.

## Approach

Files:
- `data/arrolio/glyphlist.txt` — Adobe Glyph List (port from Pdfrb).
- `lib/arrolio/font/glyph_list.rb` — parses glyphlist.txt into a
  glyph_name → Unicode String map; exposes a reverse map
  (Unicode codepoint → glyph_name).
- `lib/arrolio/font_metrics/afm_metrics.rb` — wraps an `AFM::Font`
  and exposes the universal metrics interface (see TODO 09):
  - `advance_width(char)` — Unicode char → Float (or 0 if unknown).
  - `width_of_string(str, font_size:)` — sum, scaled.
  - `ascender(font_size:)`, `descender(font_size:)`, `cap_height(font_size:)`,
    `x_height(font_size:)`, `line_height(font_size:, line_spacing:)`.

Lookup path: Unicode codepoint → AGL glyph name → AFM char_metrics[name].

## Done-When

- [ ] `AfmMetrics.for_name("Helvetica").width_of_string("Hello", font_size: 12)`
      is `27.336` (matches Adobe AFM to 0.001pt).
- [ ] `width("i") == 2.664` and `width("m") == 9.996` at 12pt.
- [ ] Non-ASCII WinAnsi chars resolve: en-dash → 556, bullet → 350.
- [ ] Ascender / descender / cap_height / x_height match AFM.
- [ ] Specs cover at least 3 of the 14 fonts (Helvetica, Times-Bold,
      Courier-Oblique).
