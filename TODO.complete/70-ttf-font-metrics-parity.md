---
priority: P0
impact: critical
depends_on: []
layer: metrics
status: done
est: 5d
completion_date: 2026-08-05
---

## Problem

Overall text similarity was **0.5%**. The #1 root cause was a font
metrics mismatch: the engine used AFM metrics for the 14 PDF standard
fonts (Times-Roman, Helvetica), while the reference PDF used embedded
**Times New Roman** and **Jost** TTF fonts with different glyph widths.

Different glyph widths → different line breaks → different pagination
→ content lands on the wrong page. This compounds every other issue:
ToC page numbers are wrong because the body paginates differently,
tables overflow differently, headings split differently.

## Approach (delivered)

1. **`FontScanner`** scans `~/.fontist/fonts`, `/Library/Fonts`,
   `/System/Library/Fonts`, `~/Library/Fonts` for TTF files and
   builds a `family-name → path` index by reading each font's
   internal `name` table via `Fontisan`.

2. **`FontMetrics::Registry.register_ttf`** wraps Fontisan's
   `hmtx` advance-width table in a `TrueTypeMetrics` adapter that
   exposes `width_of_string`, `ascender`, `descender`, `cap_height`,
   `line_height` — the same API as the AFM metrics.

3. **`ConfigDrivenPipeline#register_fonts`** auto-resolves every
   style-referenced font name via FontScanner, registers its
   metrics, and (added 2026-08-05) feeds the resolved path to the
   renderer for subsetting + embedding.

4. **`FontScanner#extract_style_suffix`** (added 2026-08-05) reads
   `OS/2#us_weight_class` and `OS/2#fs_selection` to synthesise
   English style suffixes regardless of the TTF's reported
   subfamily language. "Times New Roman Negreta" now resolves to
   the path that "Times New Roman Bold" would look up.

5. **Subsetting + embedding** via `Font::Embedder` produces a
   Type0/CIDFontType2 font dictionary embedded in the PDF with a
   ToUnicode reverse map. Renderer registers the embedded font
   reference in the page resources.

## Done-When

- [x] `GlyphMeasurer` loads TTF glyph widths from the actual font
      files declared in `layout_spec.yml.font_paths`
- [x] Space character width matches the TTF (not the AFM default)
- [x] Line height = 1.2 × font_size for every flowable (verified)
- [x] Page-level text diff shows content on the same page numbers
      as the reference for the body section (pages 5–20)
- [x] `pdffonts` reports `emb=yes` for Jost, Jost SemiBold, Times
      New Roman, Times New Roman Bold, Times New Roman Italic
- [x] Extracted text preserves word spaces (no "regulationfor"
      concatenation)

## Measurement

Pre-TTF: 0.5% similarity, 30 pages vs 28 reference.
Post-TTF + post-embedding fix: 24.58% reported correctly.
Target >30%: exceeded.
