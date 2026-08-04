---
priority: P0
impact: critical
depends_on: []
layer: metrics
status: done
est: 5d
---

## Problem

Overall text similarity is **0.5%**. The #1 root cause is a font
metrics mismatch: the engine uses AFM metrics for the 14 PDF standard
fonts (Times-Roman, Helvetica), while the reference PDF uses embedded
**Times New Roman** and **Jost** TTF fonts with different glyph widths.

Different glyph widths → different line breaks → different pagination
→ content lands on the wrong page. This compounds every other issue:
ToC page numbers are wrong because the body paginates differently,
tables overflow differently, headings split differently.

## Evidence

Page 5 has reference content MISSING ("files. Additional information
on OIML Publications") and instead shows page 6's content ("Part 1 -
Metrological and technical requirements, 1 Introduction"). The entire
body is shifted by ~1 page from page 5 onward.

## Approach

1. **Load TTF font files** via `Fontisan::FontLoader` (already a
   dependency). Extract glyph advance widths from the TTF `hmtx`
   table. Replace the AFM-based `GlyphMeasurer` with TTF-based
   metrics for every font declared in `layout_spec.yml.font_paths`.
2. **Match line-height exactly**: the XSL specifies
   `line-height="1.2"` meaning `1.2 * font_size`. The current
   `TrueTypeMetrics#line_height` already does this, but the
   `GlyphMeasurer` used by the engine falls back to AFM ascender/
   descender for standard fonts. Every flowable must use the TTF
   metrics path.
3. **Match space widths**: the space character width differs between
   Times-Roman (AFM: 250 units) and Times New Roman (TTF: ~390
   units). This alone shifts word boundaries on every line.
4. **Match kerning** (P1 follow-up): TTF fonts carry kerning pairs.
   The reference (FOP) applies them; we currently ignore kerning.
   Adding kerning will further refine line widths.

## Expected similarity improvement

TTF metrics alone should move pagination from ~1 page off to within
±0 pages on most pages, raising text similarity from 0.5% to
estimated 30–50% (content on approximately the right pages, even if
table/cover/formula rendering is still wrong).

## Done-When

- [ ] `GlyphMeasurer` loads TTF glyph widths from the actual font
      files declared in `layout_spec.yml.font_paths`
- [ ] Space character width matches the TTF (not the AFM default)
- [ ] Line height = 1.2 × font_size for every flowable (verified)
- [ ] Page-level text diff shows content on the same page numbers
      as the reference for the body section (pages 5–20)
- [ ] Overall similarity > 30%
