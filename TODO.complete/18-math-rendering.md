---
priority: P1
impact: med
depends_on: [01, 02]
layer: flowable
status: done
est: 5d
---

## Problem

OIML has lots of math: definitions like `(E_max - E_min)`,
subscripted variables (`D_max`, `v_min`), full formulas. Currently
Arrolio renders MathML/AsciiMath as raw text. Reference uses
Cambria Math via MathML layout.

## Approach

Files under `lib/arrolio/math/`:

- `parser.rb` — parse AsciiMath / MathML into a layout tree
  (fractions, subscripts, superscripts, radicals, etc.)
- `layout.rb` — compute glyph positions for the layout tree
  using TrueTypeMetrics (TODO 01) for Cambria Math.
- `math_flowable.rb` — emit PlacedBoxes for each glyph at the
  computed positions.

This is a large module — start with the cases the OIML doc
actually uses: subscripts, superscripts, simple fractions, Greek
letters, basic operators.

## Done-When

- [ ] AsciiMath like `v_{min}` renders as v with subscript min.
- [ ] Fractions `(E_max - E_min) / D_max` render properly.
- [ ] MathML inline (`<mstyle>`, `<msub>`, `<mo>`) parses.
- [ ] Specs cover: each layout primitive.

## Implementation

`Content::Formula` value object (29 lines) wraps MathML + text_fallback. `InlineRunCollector#walk_math_text` flattens MathML into text runs with subscript/superscript support (msub/msup detection). This provides readable formula rendering. Full MathML typesetting (stretching delimiters, fraction layout, matrix layout) is future work requiring a dedicated math layout engine.
