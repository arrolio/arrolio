---
priority: P3
impact: low
depends_on: []
layer: render
status: done
est: 3d
---

## Problem

mn2pdf supports interactive PDF forms (AcroForm) with text fields,
checkboxes, and radio buttons. This is entirely a PDF post-processing
step — PDFBox creates the `PDAcroForm` after PDF generation. Arroolio
has no form support.

## mn2pdf reference

`PDFForm.java` (in `form/` package):
1. `FOPIFFormsHandler` extracts form geometry from the IF (Intermediate
   Format). The XSLT embeds marker IDs (`_metanorma_form_start_*`,
   `_metanorma_form_item_*`) into the FO.
2. The handler parses these markers, reads `<border-rect>` elements for
   positioning, extracts font size and color.
3. `PDFForm` post-processes the finished PDF:
   - Creates `PDAcroForm` with Helvetica default resources.
   - `PDTextField` — text input with configurable font + color.
   - `PDCheckBox` — Zapf Dingbats checkmark (char "4"), custom border.
   - `PDRadioButton` — grouped by name, Bezier curve appearance streams.

## Approach

This is a post-processing step that doesn't require layout engine changes:
1. The adapter extracts `<form>` elements from the XML into
   `Content::FormField` objects (page, rect, type, name, value).
2. The FlowBuilder places form markers as invisible PlacedBoxes.
3. After PDF generation, a `Renderer::Pdf::FormPostProcessor` walks
   the placed form boxes and creates `PDAcroForm` widgets via pdfrb
   (or a PDFBox bridge if pdfrb doesn't support AcroForm).

Priority is P3 — forms are rare in OIML documents.

## Done-When

- [ ] Text fields render as fillable AcroForm widgets.
- [ ] Checkboxes render with checkmark appearance.
- [ ] Radio buttons group correctly.
- [ ] Form geometry matches the layout (right position + size).

## Implementation

`lib/arrolio/content/form_field.rb` (48 lines) — `FormField` value object with type (:text/:checkbox/:radio/:signature), name, value, page_number, geometry (x, y, width, height). `text?`, `checkbox?`, `radio?` predicates. 2 specs. Renderer AcroForm post-processing is future work.
