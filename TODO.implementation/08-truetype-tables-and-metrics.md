---
priority: P0
phase: 2
depends_on: [01]
layer: metrics
est: 2d
status: in_progress
---

## Problem

TTF/OTF advance widths live in the `hmtx` table indexed by glyph ID.
To go Unicode → glyph ID we need the `cmap` table. To scale we need
`head.units_per_em`. And `hhea` / `OS/2` give ascender/descender
(line height).

## Approach

Files under `lib/arrolio/font/true_type/`:

- `file.rb` — sfnt header + table directory; lazy table access.
- `head.rb` — `units_per_em`, `bbox`, `index_to_loc_format`,
  `mac_style` (bold/italic flags).
- `hhea.rb` — `ascender`, `descender`, `line_gap`,
  `number_of_hmetrics`.
- `hmtx.rb` — `advance_width(glyph_id)`, `lsb(glyph_id)`; handles
  `numberOfHMetrics < numGlyphs` case.
- `cmap.rb` — Unicode → glyph ID; subtable selection prefers
  `(3,12)` > `(0,*)` > `(3,1)` > `(3,0)`; supports formats 0, 4, 6, 12.
- `os2.rb` — `s_typo_ascender/descender/line_gap`,
  `s_cap_height`, `sx_height`, `us_win_ascent/descent`,
  `fs_selection` (bold/italic flags).

Under `lib/arrolio/font_metrics/`:

- `true_type_metrics.rb` — wraps `TrueType::File`; implements the
  universal metrics interface from TODO 09.

## Done-When

- [ ] Loading DejaVuSans.ttf (or similar fixture) succeeds.
- [ ] `ttf.head.units_per_em` matches `ttfname`/`fc-query` output.
- [ ] `ttf.cmap.glyph_id_for(0x41)` returns the same value FreeType
      reports for "A".
- [ ] `ttf.hmtx.advance_width(0)` matches the .notdef glyph width.
- [ ] `TrueTypeMetrics#width_of_string` matches FreeType to within
      0.1pt at 12pt.
- [ ] Specs cover cmap formats 4 and 12 (provide two test TTFs).
