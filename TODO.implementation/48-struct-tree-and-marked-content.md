---
priority: P2
phase: 15
depends_on: [22, 21]
layer: a11y
est: 3d
status: pending
---

## Problem

PDF/UA (ISO 14289-1) requires a structure tree: every visible
element on the page maps to a structure element (H1, P, Table, TR,
TD, Figure, etc.). The structure tree is the screen-reader path
through the document. Without it, the PDF is unreadable to
assistive technology.

## Approach

Files:

- `lib/arrolio/structure/element.rb` — `StructElement` value
  object: `type` (`:H1`, `:P`, `:Table`, `:Figure`, etc.),
  `content_ref` (link to the PlacedBox that materialises this),
  `children`, `attributes`.

- `lib/arrolio/structure/tree.rb` — `StructTreeRoot` builder.
  Walks the Output tree; for each PlacedBox with a `struct_role`
  attribute, emits a StructElement.

- Marked content in the content stream: every visible drawing
  operation is wrapped in `BDC`/`EMC` operators with a `/MC`
  property list referencing the StructElement.

- `lib/arrolio/renderer/pdf/struct_emitter.rb` — emits:
  - `/StructTreeRoot` on Catalog.
  - `/Type /StructElem` entries.
  - `/ParentTree` mapping content-stream MCIDs to StructElems.
  - `/MarkInfo /true` on Catalog.

## Done-When

- [ ] A simple paragraph emits `<P>` structure element.
- [ ] A heading emits `<H1>` with correct heading level.
- [ ] A table emits `<Table><TR><TH>...</TH></TR></Table>`.
- [ ] An image emits `<Figure>` with `/Alt` text.
- [ ] `/MarkInfo /true` is present on Catalog.
- [ ] Round-trip: re-read PDF has a `/StructTreeRoot`.
- [ ] A screen reader (NVDA or similar) can navigate the document.
