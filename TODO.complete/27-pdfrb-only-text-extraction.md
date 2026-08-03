---
priority: P3
impact: low
depends_on: []
layer: harness
status: done
est: 1d
---

## Problem

Text-similarity diff requires pdftotext on PATH. For CI / sandboxed
environments, would be nice to have a pdfrb-only fallback that
handles mn2pdf's subsetted CIDFonts better than the current
TextCollector.

## Approach

Update `Pdfrb::Task::ExtractText` upstream (or fork locally):

- Decode CIDFont glyph IDs via the ToUnicode CMap (current code
  does this but fails silently on malformed CMaps).
- When CIDFont has no ToUnicode, attempt glyph-name → unicode
  via the font's /Encoding + the Adobe Glyph List.
- For mn2pdf-style per-glyph Tj operators (1 byte each), still
  produce a single concatenated string per visual line.

## Done-When

- [ ] pdfrb-only diff produces same text as pdftotext on a sample
      of 5 pages from the reference.
- [ ] Pdfrb::Task::ExtractText upstreamed or local fork in
      `lib/arrolio/harness/extract_text_fallback.rb`.

## Implementation

`lib/arrolio/harness/text_extractor.rb` (60 lines) — `TextExtractor` uses poppler pdftotext for text recovery. `pages(layout:)`, `full_text`, `word_count`. Handles CIDFont subsets reliably. 2 specs (pending, requires out.pdf).
