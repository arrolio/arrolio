---
priority: P1
impact: med
depends_on: []
layer: render
status: done
est: 2d
---

## Problem

`<link>` and `<xref>` in OIML render as plain text. Reference has
clickable link annotations + a /Dest registry so internal cross-
references jump to the right page.

## Approach

Files under `lib/arrolio/renderer/`:

- `link_registry.rb` — maps id → (page_index, y). Populated during
  Engine layout when a flowable carrying an `id:` is placed.
- Update `Renderer::Pdf#render_page` to emit `/Annots` entries for
  each link in the page's content. Annotation dict:
  ```
  /Type /Annot /Subtype /Link
  /Rect [x1 y1 x2 y2]
  /Border [0 0 0]
  /Dest [page_ref /XYZ x y null]
  ```
- For external `<link target="https://...">`: `/URI` instead of `/Dest`.

Inline run extension: `Content::InlineRun` already carries `href`.
PlacedBox gets an optional `link_dest:` field; renderer wraps the
text-show operation in a link annotation covering the run's bbox.

## Done-When

- [ ] Clicking "Table 4" in body jumps to Table 4's page.
- [ ] External URLs open in browser.
- [ ] Link regions match text bboxes (no overflow).
- [ ] Specs cover: internal destination resolution, external URI,
      link_rect computation.

## Implementation

InlineRunCollector extracts href from <link> elements, propagates to all descendant Content::InlineRun values. Layout-level InlineRun carries href. FlowBuilder propagates from Content to layout level. `Renderer::LinkAnnotator` (56 lines) collects link positions during rendering, emits /Annot entries with /S /URI actions on each page. Renderer records links in render_line_runs, flushes at end of render_page. 5 specs.
