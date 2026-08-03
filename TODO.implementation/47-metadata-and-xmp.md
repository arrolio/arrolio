---
priority: P2
phase: 14
depends_on: [22]
layer: color
est: 2d
status: pending
---

## Problem

Production PDFs carry metadata: title, author, subject, keywords,
creation/modification dates, plus an XMP stream for ISO 19005-2
(PDF/A) compliance. Arrolio currently writes nothing.

## Approach

Files:

- `lib/arrolio/metadata/info.rb` — `Info` value object with the
  classic `/Info` dict fields: `:Title`, `:Author`, `:Subject`,
  `:Keywords`, `:Creator`, `:Producer`, `:CreationDate`,
  `:ModDate`.

- `lib/arrolio/metadata/xmp.rb` — builds an XMP packet (XML)
  containing Dublin Core + PDF + PDF/A schemas. Stored as a
  `/Metadata` stream on Catalog (`/Type /Metadata /Subtype /XML`).

- Renderer (TODO 22) integration: after rendering pages, write
  `/Info` to trailer and `/Metadata` to Catalog.

Date format: PDF date strings `D:YYYYMMDDHHmmSSOHH'mm'`.

## Done-When

- [ ] A document rendered with `metadata: { title: "My Doc", author:
      "Jane" }` has those fields in `/Info`.
- [ ] `/CreationDate` and `/ModDate` are valid PDF date strings.
- [ ] XMP packet is valid XML; parses with REXML.
- [ ] XMP contains `dc:title`, `dc:creator`, `pdf:Producer`.
- [ ] Round-trip: re-read PDF exposes the metadata via Pdfrb.
