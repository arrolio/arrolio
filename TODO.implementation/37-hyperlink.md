---
priority: P1
phase: 11
depends_on: [36, 22]
layer: inline
est: 2d
status: pending
---

## Problem

Hyperlinks (`<a href="...">` in HTML, `fo:basic-link` in FO) need
both inline rendering (the visible text) and annotation emission (a
PDF link annotation over the run's bounding box). The bounding box
isn't known until layout — link annotations are added in a
post-layout pass.

## Approach

Files:

- `lib/arrolio/hyperlink.rb` — `Hyperlink < InlineRun` with
  `destination` (URI string or internal destination name).
  Carries an `annotation_id` that the renderer fills in after
  placement.

- `lib/arrolio/output/link_annotation.rb` — `LinkAnnotation` value
  object: `rect` (x, y, w, h), `destination` (URI or page ref),
  `border_style`.

Engine integration:
- During TextFlowable render, track each Hyperlink run's bounding box
  (compute from line position + run width).
- After all body content is placed, walk the Output tree collecting
  Hyperlinks → emit `LinkAnnotation[]` per page.
- PDF renderer (TODO 22) walks LinkAnnotations → emits `/Annots`
  array entries on each page.

Two kinds of destination:
- **External** (URI): `/S /URI /URI (https://...)`.
- **Internal** (page reference): `/S /GoTo /D [page_ref /Fit]`.
  Requires a destination registry (TODO 41).

## Done-When

- [ ] A paragraph with a hyperlink run renders the text in blue
      underline (style default) and emits a clickable annotation.
- [ ] External URI links open correctly when the PDF is viewed.
- [ ] Internal links jump to the correct page (integration with
      TODO 41 destinations).
- [ ] Multiple hyperlinks on the same page each get distinct
      `/Annots` entries.
- [ ] Re-read PDF has the expected annotation structure.
