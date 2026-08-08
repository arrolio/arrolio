---
priority: P2
impact: medium
depends_on: [75]
layer: flowable
status: pending
est: 1d
---

## Problem

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
