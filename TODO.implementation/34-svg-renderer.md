---
priority: P1
phase: 10
depends_on: [22]
layer: media
est: 3d
status: pending
---

## Problem

SVG inside documents (`<svg>...</svg>` blocks, FOP's
`fo:instream-foreign-object`) need a renderer. The SVG renderer
walks the SVG tree and emits drawing operations on a Canvas (Pdfrb
content stream). Supports the FOP/Batik output subset.

## Approach

Files under `lib/arrolio/svg/`:

- `document.rb` — wraps a parsed SVG (REXML); exposes `width`,
  `height`, `view_box`, `root`.

- `style.rb` — resolved style from element attributes (fill, stroke,
  stroke_width, opacity, font_*). Inherits from parent. Class
  method `color_to_pdf(color_string)` resolves named/hex to PDF
  Canvas colour.

- `transform_parser.rb` — `parse("translate(10,20) rotate(45)")`
  → list of op/args. `to_matrix(transforms)` → 6-element affine.

- `path_parser.rb` — `parse("M 10 10 L 90 10 Z")` → list of
  `{cmd:, absolute:, args:}`. Supports M L H V C S Q T A Z.

- `element.rb` — base class with `register "name"` class method;
  `for_element(xml, style:)` dispatcher.

- Element subclasses under `lib/arrolio/svg/element/`:
  - `group.rb` (g) — applies transform + recurses.
  - `path.rb` — PathState accumulator; emits move/line/curve/close.
  - `rect.rb`, `circle.rb`, `ellipse.rb`, `line.rb`,
    `polyline.rb`, `polygon.rb` — basic shapes.
  - `text.rb` — single-line text.
  - `image.rb` — embedded raster (data: URI or href).

- `renderer.rb` — walks Document, dispatches to element classes,
  maintains transform/style stack.

## Done-When

- [ ] `<rect width="100" height="50" fill="red"/>` renders a red rectangle.
- [ ] `<circle cx="50" cy="50" r="20"/>` renders via Bezier approximation.
- [ ] `<path d="M 10 10 L 90 10 L 50 90 Z" fill="red"/>` renders triangle.
- [ ] `<g transform="translate(10,10)"><rect .../></g>` translates children.
- [ ] Nested groups compose transforms correctly.
- [ ] `<text x="10" y="20">Hello</text>` renders text.
- [ ] `<image xlink:href="data:image/png;base64,..."/>` renders PNG.
- [ ] Spec coverage for each element type.
