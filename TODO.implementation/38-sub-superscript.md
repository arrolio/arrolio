---
priority: P2
phase: 11
depends_on: [10]
layer: inline
est: 1d
status: pending
---

## Problem

Footnote markers, mathematical exponents, chemical formulae all need
sub/superscript: small text raised (or lowered) relative to the
baseline. The TextLayout must place these correctly without breaking
the line height.

## Approach

Extend `Arrolio::InlineRun` (TODO 10) with two style properties:
- `text_rise` (Float, in points) — vertical offset from baseline.
  Positive = superscript; negative = subscript.
- The existing `font_size` already supports smaller sizes.

Add helper methods to `InlineBuilder` (TODO 36):
- `superscript(str)` → `style.with(font_size: size * 0.7,
  text_rise: size * 0.5)`.
- `subscript(str)` → `style.with(font_size: size * 0.7,
  text_rise: -(size * 0.2))`.

TextLayout integration:
- When measuring a run with `text_rise`, line height calculation
  accounts for the raised extent (extends above ascender).
- When rendering, emit `canvas.text(...)` with Pdfrb's `Tz` (rise)
  parameter (PDF text-rise operator).

## Done-When

- [ ] `superscript("2")` renders smaller and raised.
- [ ] `subscript("n")` renders smaller and lowered.
- [ ] Line containing a superscript doesn't have its height reduced
      (the rise doesn't push out of the line box; line_height is
      generous enough).
- [ ] "x² + y²" renders correctly with raised 2's.
- [ ] "H₂O" renders with subscript 2.
