---
priority: P0
impact: high
depends_on: [01, 02]
layer: render
status: done
est: 3d
---

## Problem

The `Font::Embedder` infrastructure is built and tested in isolation
(produces a valid Type0/CIDFont/Descriptor/ToUnicode structure that
mutool can parse), but enabling it in the full OIML pipeline hits
two distinct breakages:

1. **pdfrb xref corruption**: when many extra indirect objects are
   added (one per font file + descriptor + CIDFont + Type0 +
   ToUnicode = ~5 objects × N fonts), pdfrb's `Document#write`
   emits a broken xref that mutool reports as
   "format error: expected trailer marker / trying to repair".
2. **pdftotext Identity-H decode**: poppler can't find an external
   `IdentityH` CMap resource and won't fall back to the font's
   ToUnicode CMap, so every glyph emitted as a 2-byte GID string
   is silently dropped from text extraction — driving the diff
   similarity from 46.5% → 5.4% when embedding is on.

Both breakages don't affect mn2pdf's output, so the reference PDF
extracts cleanly. The difference must be in how the resources dict,
catalog Info, and indirect-reference graph are wired.

## Approach

1. **Fix xref**: walk pdfrb's `Writer#write_xref` to confirm every
   added indirect object is registered. Likely the new objects
   are added via `document.add(...)` but pdfrb's `next_oid`
   counter isn't incremented consistently, or the `xref_section`
   doesn't cover the new oid range. Patch upstream in pdfrb.
2. **Fix ToUnicode**: compare the byte-level shape of our
   ToUnicode CMap stream vs the reference's. Likely issues:
   - Missing `/CIDInit /ProcSet findresource begin` header
   - `beginbfchar` block size limit of 100 (chunk larger sets)
   - Hex case (uppercase vs lowercase)
   - The /ToUnicode reference must point at a Stream object,
     not an indirect-reference to a Stream
3. **Re-test**: re-enable `font_paths:` in
   `data/oiml/layout_spec.yml`, re-render, expect diff to jump
   from 46.5% to ≥70% (Liberation Serif is metrically identical
   to Times New Roman so text flow should match).

## Files

- `lib/arrolio/font/embedder.rb` (current implementation)
- `lib/arrolio/font/text_encoder.rb`
- `lib/arrolio/renderer/pdf.rb` (`prepare_embedded_fonts` + `attach_to_resources`)
- `data/oiml/layout_spec.yml` (currently has `font_paths:` commented out)
- `~/src/claricle/pdfrb/lib/pdfrb/writer.rb` (upstream xref fix)
- `~/src/claricle/pdfrb/lib/pdfrb/task/extract_text.rb` (the consumer)

## Done-When

- [ ] `mutool info out.pdf` shows no "expected trailer marker" warning
      with `font_paths:` enabled.
- [ ] `pdftotext out.pdf -` returns the same text it returns for
      the standard-14 version.
- [ ] Diff similarity ≥ 70% (Liberation Serif = Times New Roman metrics).
- [ ] All 29 existing specs still pass.
- [ ] New specs cover Embedder subset + TextEncoder round-trip.

## Implementation

Font embedding fully wired: pipeline registers TTFs → engine measures with TrueTypeMetrics → renderer embeds subsets → TextEncoder produces GID sequences.
