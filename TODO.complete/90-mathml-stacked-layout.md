---
priority: P2
impact: medium
depends_on: [75]
layer: flowable
status: pending
est: 1d
---

## Problem

MathML stacked layout (mfrac, msqrt) renders flat.

## Measured nuance (2026-08-19)

Do NOT expand line height for every line carrying sub/superscript
runs: the reference keeps ordinary symbol sub/sups compact (the
terminology region's E_min/D_max/v_min lines are single-height and
were aligned). Only the parenthesized display-style expressions
(e.g. 5.3.2's ": (0.3 <= pLC <= 0.8)," after a colon) lay out stacked
- whole expression ~10pt below the text baseline, parens at the
text level, box two lines tall. A global 1.9x on math lines was
tested and overshoots the document by 2 pages (29 vs 28). The
discriminator between compact sub/sup and stacked expressions is in
the base XSL's stem handling (not the OIML extension) - find it
before implementing.


MathML fractions (`<mfrac>`) render as "numerator denominator" on one
line instead of a stacked fraction. Other stacked elements (mroot,
msqrt) also need vertical layout.

## Current state

- MathML integration: SHIPPED (plurimath/mml)
- `ELEMENT_HANDLERS` registry: mi, mn, mo, msub, msup, msubsup, mfrac
- 10 specs covering basic elements

## Approach

1. **Stacked fraction flowable.** Create a `MathFractionFlowable` that
   renders numerator centered above denominator with a horizontal rule.

2. **Vertical layout in renderer.** The renderer needs to handle
   `Output::PlacedBox` with `data[:type] == :math_fraction`:
   - Draw numerator at top
   - Draw horizontal rule at middle
   - Draw denominator at bottom

3. **Mroot/msqrt.** Render radical sign with content.

4. **Mtable.** Render simple matrices.

## Done-When

- [ ] `<mfrac>` renders as stacked fraction with dividing line
- [ ] `<msqrt>` renders with radical sign
- [ ] `<mroot>` renders with index
- [ ] Math content vertically centered in line
- [ ] Specs cover fraction, sqrt, root

## Measurement

Affects ~5 formula references in OIML body text.
Last measured: 2026-08-08.
