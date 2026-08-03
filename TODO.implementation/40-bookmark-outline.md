---
priority: P1
phase: 12
depends_on: [22, 26]
layer: xref
est: 2d
status: pending
---

## Problem

PDF outlines (the bookmark panel in viewers) let users navigate.
Each entry is a title + destination. The outline tree mirrors the
document's section structure. Currently Arrolio doesn't emit one.

## Approach

Files:

- `lib/arrolio/output/outline_node.rb` — value object: `title`,
  `destination` (page_ref + viewport), `children` (Array), `parent`.

- `lib/arrolio/renderer/pdf/outline_emitter.rb` — walks the
  OutlineNode tree, builds Pdfrb objects:
  - `/Outlines` (root dict) on Catalog.
  - `/Type /Outlines`, `/First`, `/Last`, `/Count`.
  - Per outline entry: `/Title`, `/Parent`, `/Dest` (page ref + view),
    `/First`/`/Last`/`Next`/`Prev`/`Count` for hierarchy.

Engine integration:
- During pass 1, when placing a flowable that has a `bookmark_target`
  attribute, record `context.record_bookmark(ref_id, page_number, y)`.
- After pass 1, build the OutlineNode tree from recorded bookmarks.
- Pass 2 emits the outline via OutlineEmitter.

Bookmark target source: `Content::Section` carries an `id`; the
content adapter (or the Composer) registers these as bookmark targets.

## Done-When

- [ ] A document with 3 sections produces a 3-entry outline.
- [ ] Nested sections produce nested outline entries.
- [ ] Clicking an outline entry in a viewer jumps to the right page.
- [ ] Outline `/Count` reflects open/closed state default.
- [ ] Re-read PDF has the expected `/Outlines` structure.
