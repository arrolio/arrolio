---
priority: P2
phase: 19
depends_on: [22]
layer: conformance
est: 2d
status: pending
---

## Problem

Modeled on `veraPDF/features/`, Arrolio needs a feature extractor
that walks a PDF (ours or a third-party's) and produces a structured
feature report — fonts used, images embedded, colour spaces, page
sizes, annotations, signatures, metadata. Useful for:

- Debugging: "why does this PDF render wrong on viewer X?"
- Conformance pre-checks before running full validation.
- Diff inputs (compare features between two PDFs as a quick scan).
- Documentation: "what does this PDF contain?"

## Approach

Files under `lib/arrolio/conformance/features/`:

- `feature_extractor.rb` — top-level orchestrator; walks a
  `Pdfrb::Document`, dispatches per object type, accumulates
  `FeatureReport`.

- `feature_report.rb` — frozen value object: pages, fonts, images,
  colour_spaces, annotations, signatures, metadata, embedded_files,
  outlines, acroform_fields.

- Per-category extractors:
  - `font_features.rb` — base_font, subtype, embedded?, encoding,
    to_unicode?, num_glyphs.
  - `image_features.rb` — width, height, bits_per_component, color_space,
    filter, embedded?, smask?.
  - `color_space_features.rb` — name, type (DeviceRGB/CMYK/ICC/etc.),
    icc_profile?.
  - `annotation_features.rb` — subtype, rect, action.
  - `page_features.rb` — mediabox, rotate, contents_size,
    annotation_count.
  - `metadata_features.rb` — info dict fields, xmp_packet?.

- `feature_serializer.rb` — `to_yaml`, `to_json`, `to_html_table`.

### Diff integration

A `feature_diff` mode that compares two FeatureReports and emits a
summary ("font Helvetica added", "image /Im3 missing in v2"). This
is a fast pre-check before the full semantic comparator (TODO 55).

## Done-When

- [ ] FeatureExtractor produces a complete FeatureReport on a
      fixture PDF.
- [ ] All category extractors run without error on FOP-produced PDFs.
- [ ] YAML/JSON/HTML serialisation works.
- [ ] A simple "feature_diff" highlights added/removed/changed
      features between two PDFs.
- [ ] Round-trip: extract from rendered PDF shows expected font
      list, image count, page count.
- [ ] Spec coverage for each category extractor.
