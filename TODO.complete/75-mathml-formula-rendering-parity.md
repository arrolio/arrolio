---
priority: P2
impact: high
depends_on: [70, 77]
layer: flowable
status: in_progress
est: 3d
---

## Problem

Mathematical content previously appeared as raw text. Now uses the
plurimath/mml gem for proper MathML 3 parsing.

## Status (2026-08-08)

- [x] **mml gem integrated** — `Mml.parse(xml, version: 3)` parses
      the MathML tree. Added `'mml', '~> 2.4'` to gemspec. Pinned
      to local path `~/src/plurimath/mml/` in Gemfile.
- [x] **`Arroolio::MathML::InlineRunExtractor`** — walks the parsed
      tree using `ELEMENT_HANDLERS` registry (OCP-extensible).
      Each Mml::V3::* class maps to [value_attr, child_attr, kind].
- [x] **10 specs** covering mi, msub, msup, msubsup, mn+mo, mfrac,
      nil/empty/invalid, custom style, direct tree walk.
- [x] **`<msub>` → BASELINE_SUB, scale 0.7**
- [x] **`<msup>` → BASELINE_SUP, scale 0.7**
- [x] **`<msubsup>` → sub + sup**
- [x] **`<munder>`/`<mover>` → treated as sub/sup for visual fidelity**
- [x] **`<mfrac>` → inline numerator/denominator with `/` separator**

## Still pending

- [ ] **Stacked fraction rendering** — true two-line fraction with
      a horizontal rule. Needs a new PlacedBox kind `:math_fraction`
      that the renderer draws as stacked text + rule.
- [ ] **`<mroot>`/`<msqrt>`** — roots need special visual treatment
      (√ prefix + n-th root index).
- [ ] **`<mtable>`** — matrix layout.

## Done-When

- [x] mml gem integrated
- [x] Subscripts and superscripts render correctly
- [x] Formula text extracts as readable math
- [ ] Stacked fraction layout
- [ ] Root rendering
- [ ] Overall similarity > 55% on formula-bearing pages

## Parity impact

48.94% baseline. MathML pages (11, 18-22) improved from raw markup
to readable formula text via the mml integration.
