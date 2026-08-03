---
priority: P0
phase: 6
depends_on: [20]
layer: output
est: 2d
status: in_progress
---

## Problem

Engine produces laid-out pages but currently they're tied to Pdfrb's
page object. The Output tree should be a medium-neutral representation
of "what goes where" — separate from both the layout algorithm and
the renderer. The PDF renderer walks the Output tree; future
renderers (PostScript, PPML, an in-memory canvas for tests) walk the
same tree.

## Approach

Files under `lib/arrolio/output/`:

- `page.rb` — `Page` value object:
  - `number` (Integer)
  - `template_ref` (Symbol or PageTemplate reference)
  - `regions` (Hash of region_name → Region)
  - `static_content` (Array of StaticContent)
  - `size` (Array `[w, h]`)

- `region.rb` — `Region` value object:
  - `name` (`:body`, `:before`, `:after`, ...)
  - `frame` (the consumed Frame snapshot)
  - `placed_boxes` (Array of PlacedBox)

- `placed_box.rb` — `PlacedBox` value object:
  - `x`, `y`, `width`, `height` (Float)
  - `content_ref` (opaque reference to the source flowable or run)
  - `style` (resolved Style::Definition snapshot)
  - `kind` (`:text`, `:image`, `:shape`, ...)

- `static_content.rb` — region name + a list of flowables (rendered
  in pass 2 with resolved citations).

The Output tree is fully reified before rendering — no lazy
generation. This makes rendering straightforward and lets us diff
Output trees between runs.

## Done-When

- [ ] Engine returns `[Output::Page]`.
- [ ] Each Page has at least a body Region with placed_boxes.
- [ ] StaticContent records region + flowables but doesn't render
      until pass 2.
- [ ] Output tree is fully frozen; no mutation after construction.
- [ ] `Output::Dumper.to_yaml(page)` produces a stable, diffable
      representation.
