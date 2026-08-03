---
priority: P1
phase: 12
depends_on: [22, 39]
layer: xref
est: 1d
status: pending
---

## Problem

Internal hyperlinks (`PageNumberCitationField` links,
`Hyperlink` runs pointing to a section) need named destinations
that resolve to specific (page, viewport) pairs. Currently nothing
records where a `ref_id` lands.

## Approach

Files:

- `lib/arrolio/destination.rb` — `Destination = Struct.new(:ref_id,
  :page_number, :x, :y, :zoom, keyword_init: true)`. The `ref_id`
  is the author's identifier (e.g. "section_3"); page_number and
  viewport are filled in during layout.

- `lib/arrolio/output/destination_registry.rb` — collects
  `Destination` instances during pass 1; resolves by `ref_id` in
  pass 2.

- `lib/arrolio/renderer/pdf/destination_emitter.rb` — emits:
  - **Named destinations**: `/Names /Dests << /Name (page_ref /Fit) >>
    >>` on Catalog (or a dedicated Names dict).
  - **Page-relative destinations**: stored inline in the link
    annotation's `/D` array.

Engine integration:
- When the engine places a flowable with a `destination_id`
  attribute, record a Destination at the current page number and the
  flowable's top y.
- Pass 2 walks the Output tree; for each Hyperlink or
  PageNumberCitationField pointing to a `ref_id`, look up the
  Destination.

## Done-When

- [ ] A section heading with `id: "intro"` records a Destination
      pointing to its page.
- [ ] A hyperlink to "intro" jumps to the correct page in a viewer.
- [ ] A `PageNumberCitationField` referencing "intro" shows the
      correct page number.
- [ ] Missing `ref_id` raises a clear error during pass 2.
- [ ] Re-read PDF has the expected `/Names /Dests` or `/Dests` dict.
