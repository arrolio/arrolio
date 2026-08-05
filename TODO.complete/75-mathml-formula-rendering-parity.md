---
priority: P2
impact: med
depends_on: [70, 77]
layer: flowable
status: pending
est: 3d
---

## Problem

Mathematical content currently appears as raw text in the rendered
PDF: `E_{"max"}`, `v_{"min"}`, `p_{"LC"} = 0.7`, `+30 "unitsml(degC)"`,
`xx`. The reference renders these as proper MathML formulas with
subscripts, superscripts, and unit formatting.

Pages 11, 18, 19, 20, 21, 22 contain mathematical expressions that
suffer from this.

## Approach

1. **MathML → inline runs**: the adapter already has `walk_math` and
   `walk_stem` in the inline walker. Currently they flatten raw text.
   Instead, they should interpret the MathML structure:
   - `<msub>` → subscript baseline shift (uses the new
     `Content::InlineRun::BASELINE_SUB` from TODO 77)
   - `<msup>` → superscript baseline shift (`BASELINE_SUP`)
   - `<mfrac>` → fraction (two stacked runs, smaller font_size_scale)
   - `<mtext>` → literal text run
   - `<mi>`, `<mn>`, `<mo>` → styled math runs (italic for `<mi>`)

2. **Unit formatting**: OIML uses AsciiMath/UnitsML inline. The
   presentation XML wraps these in `<stem>` elements with
   `<asciimath>` or `<latexmath>` children. The `fmt-stem` element
   carries the rendered MathML. Parse the `fmt-stem` MathML tree
   and emit `InlineRun`s with appropriate `baseline_shift` and
   `font_size_scale`.

3. **Sub/sup wired through**: TODO 77 (sub/sup baseline) shipped
   the `Content::InlineRun#baseline_shift` plumbing. MathML
   `<msub>`/`<msup>` reuse the same path; the walker just needs
   to set the shift when descending into these elements.

4. **Fraction layout**: `<mfrac>` is the hard case. It needs a
   new Flowable (or PlacedBox kind) that stacks two short text
   runs above and below a horizontal rule. Defer to a follow-up
   if time-constrained — `<msub>`/`<msup>` cover most of the
   OIML math content.

## Done-When

- [ ] `<msub>` renders as subscript
- [ ] `<msup>` renders as superscript
- [ ] `<mi>` italic, `<mn>` regular, `<mo>` regular
- [ ] `<mfrac>` renders as a two-line fraction (optional — defer)
- [ ] Formula text extracts as readable math (not raw markup)
- [ ] Pages 11, 18-22 show formula content matching the reference

## Expected improvement

Fixes formula rendering on pages 11, 18-22. Estimated 3-5%
overall similarity improvement (text content matches when formulas
render as readable math instead of raw markup).

## Status (2026-08-05)

Sub/sup baseline plumbing shipped (TODO 77). MathML walker still
flattens — needs the per-element dispatch added to walk_math.
