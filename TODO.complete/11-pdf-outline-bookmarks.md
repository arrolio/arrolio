---
priority: P1
impact: low
depends_on: []
layer: render
status: done
est: 1d
---

## Problem

Reference PDF has a /Outlines tree so PDF readers show a
bookmark sidebar: every section + annex + bibliography as a
nested entry. Arrolio emits no outlines.

## Approach

File: `lib/arrolio/renderer/outline_builder.rb`

Walk the FlowContext's collected `heading_entries` (added in
TODO 09) — same data the ToC uses. Emit:

```
/Outlines << /Type /Outlines /First N 0 R /Last M 0 R /Count K >>
```

Each outline item:
```
/Type /Outlines
/Title (section number + title)
/Parent ...
/First ... /Last ... /Next ... /Prev ...
/Dest [page_ref /XYZ x y null]
```

Wire into `Renderer::Pdf#render` after all pages are placed.

## Done-When

- [ ] PDF reader shows bookmark sidebar with all 6 sections +
      bibliography, nested sub-sections under each.
- [ ] Clicking a bookmark jumps to the right page.
- [ ] Specs cover: outline tree shape, nesting, dest references.

## Implementation

`lib/arrolio/renderer/outline_builder.rb` — builds /Outlines tree from FlowContext#heading_entries. 67 bookmarks generated.
