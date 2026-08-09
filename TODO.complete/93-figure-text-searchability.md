---
priority: P2
impact: medium
depends_on: [84]
layer: render
status: pending
est: 3d
---

## Problem

SVG figures rendered via rsvg-convert are rasterized to PNG. Text
inside the figures (labels, annotations) becomes pixels and is not
searchable in the PDF. The reference mn2pdf/FOP renders SVG as vector
content, preserving text searchability.

This accounts for ~1,500 characters of the remaining text content gap
(53,472 vs 55,534 reference). Figure labels like "Peripheral devices",
"Keyboard to operate", "Maximum capacity Emax", etc. are visible in
the reference's pdftotext output but absent from ours.

## Approach

1. **Vector SVG embedding.** Instead of rasterizing via rsvg-convert,
   embed the SVG as a PDF XObject (Form XObject). This preserves text
   as actual PDF text operators.

2. **Text overlay.** Alternatively, rasterize the SVG for visual
   fidelity but add an invisible text layer with the SVG's text
   content. The text layer is marked as invisible but searchable.

3. **SVG text extraction.** Parse the SVG XML to extract all `<text>`
   elements with their positions. Use these to create searchable text
   in the PDF at the corresponding coordinates.

Option 3 is the most pragmatic: it doesn't require vector rendering
support but makes figure text searchable.

## Done-When

- [ ] Figure text content appears in pdftotext output
- [ ] Text positions match visual figure positions
- [ ] No visual regression in figure rendering
- [ ] Text content gap reduced from ~2,000 to <500 chars

## Measurement

`pdftotext` char count comparison. Currently 53,472 vs 55,534.
Last measured: 2026-08-09.
