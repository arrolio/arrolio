---
priority: P1
impact: med
depends_on: [70]
layer: flowable
status: pending
est: 3d
---

## Problem

Mathematical content appears as raw text: `E_{"max"}`, `v_{"min"}`,
`p_{"LC"} = 0.7`, `+30 "unitsml(degC)"`, `xx`. The reference renders
these as proper MathML formulas with subscripts, superscripts, and
unit formatting.

Pages 11, 18, 19, 20, 21, 22 contain mathematical expressions that
are currently unrendered.

## Approach

1. **MathML → inline runs**: the adapter already has `walk_math` and
   `walk_stem` in the inline walker. Currently they extract raw text.
   Instead, they should interpret the MathML structure:
   - `<msub>` → subscript baseline shift
   - `<msup>` → superscript baseline shift
   - `<mfrac>` → fraction (two lines, smaller font)
   - `<mtext>` → literal text
   - `<mi>`, `<mn>`, `<mo>` → styled math runs
2. **Unit formatting**: OIML uses AsciiMath/UnitsML inline. The
   presentation XML wraps these in `<stem>` elements with
   `<asciimath>` or `<latexmath>` children. The `fmt-stem` element
   carries the rendered MathML. Parse the `fmt-stem` MathML and emit
   `InlineRun`s with appropriate `baseline_shift` and
   `font_size_scale`.
3. **Subscript/superscript**: `InlineRun` already supports
   `baseline_shift: :sub` and `:sup`. The adapter walker must detect
   `msub`/`msup` and apply these.

## Expected improvement

Fixes formula rendering on pages 11, 18–22. Estimated 5%
similarity improvement (text content matches when formulas render
as readable math instead of raw markup).

## Done-When

- [ ] `<msub>` renders as subscript
- [ ] `<msup>` renders as superscript
- [ ] `<mfrac>` renders as a two-line fraction
- [ ] Formula text extracts as readable math (not raw markup)
- [ ] Pages 11, 18–22 show formula content matching the reference
