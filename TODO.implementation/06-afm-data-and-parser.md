---
priority: P0
phase: 2
depends_on: [01]
layer: metrics
est: 1d
status: in_progress
---

## Problem

The 14 standard Type1 fonts (Helvetica, Times, Courier + variants,
Symbol, ZapfDingbats) need real glyph widths for line breaking. The
canonical source is Adobe Font Metrics files (AFM). Arrolio bundles
its own copy so it doesn't depend on Pdfrb's data dir.

## Approach

Files:
- `data/arrolio/afm/*.afm` — 14 AFM files (port from
  `pdfrb/data/pdfrb/afm/`).
- `lib/arrolio/font/afm_parser.rb` — parses `StartFontMetrics` block,
  `FontName`/`FullName`/`FamilyName`, `FontBBox`, `CapHeight`,
  `XHeight`, `Ascender`, `Descender`, `StartCharMetrics`/`EndCharMetrics`,
  and each `C N ; WX W ; N name ; B bbox ;` row.

Parser produces a frozen `AFM::Font` value object with `char_metrics`
hash keyed by both code and glyph name.

## Done-When

- [ ] All 14 AFM files load without error.
- [ ] `AFMParser.from_file("data/arrolio/afm/Helvetica.afm").font_name`
      == `"Helvetica"`.
- [ ] Helvetica's `A` width is 668 (per AFM); `i` is 222; `m` is 833.
- [ ] Ascender/descender/cap_height/x_height parsed for all 14.
- [ ] Specs cover the parser on at least 3 of the 14.
