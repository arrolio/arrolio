---
priority: P1
impact: high
depends_on: [79]
layer: text
status: pending
est: 2d
---

## Problem

List item body paragraphs sometimes lose text after cross-references.
The placed box correctly contains 2 lines of text (verified via debug),
but the renderer only outputs line 1 — line 2 is silently dropped.

## Example

Input paragraph:
```
For legally relevant software of digital load cells the following
statements according to [OIML_D_31_2008] shall be applied.
```

Placed box (verified correct):
- Line 0: "For legally relevant software of digital load cells..."
- Line 1: "according to [OIML_D_31_2008] shall be applied."

Rendered PDF:
- Line 1 ends at "shall"
- "be applied." is MISSING
- Nested list item "1)" appears immediately after

## Root cause hypothesis

The `ListFlowable#emit` computes `body_width` correctly (427pt) and the
`TextFlowable` produces 2 lines at that width. But the RENDERED text
overflows the body width by ~74pt (extends to x=597 vs max x=523).

This suggests a **measurement discrepancy**: the GlyphMeasurer computes
text width differently from the embedded font renderer. The `[OIML_D_31_2008]`
token (with underscores and brackets) may have different glyph widths in
the TTF metrics vs the PDF rendering.

## Approach

1. **Audit measurement vs rendering width.** Compare GlyphMeasurer
   output for `[OIML_D_31_2008]` against the actual rendered width
   in the PDF.

2. **Check font substitution.** If the renderer falls back to
   Helvetica for some glyphs, widths will differ. Verify that ALL
   characters in `[OIML_D_31_2008]` exist in the embedded
   Times New Roman subset.

3. **Check subset coverage.** The font embedder may not include
   underscore (`_`) or brackets (`[`, `]`) in the subset, causing
   fallback rendering.

4. **Force-include punctuation glyphs.** Ensure `[`, `]`, `_`, `(`,
   `)` are always in the subset even if they appear only in
   cross-references.

## Done-When

- [ ] "be applied." renders after "shall" in list item b)
- [ ] Text never overflows body width in list items
- [ ] GlyphMeasurer widths match rendered widths within 1pt
- [ ] Specs cover list item with long inline tokens

## Measurement

Affects ~3-5 list items with long bracketed references.
Last measured: 2026-08-08.
