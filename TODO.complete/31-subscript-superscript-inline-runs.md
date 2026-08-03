---
priority: P0
impact: high
depends_on: [30]
layer: content
status: done
est: 1d
---

## Problem

MathML formulas with subscripts/superscripts render as flat text:
"Dmin" instead of "D_min", "nLC" instead of "n_LC". The content
model (`Content::InlineRun`) has no concept of baseline shift —
all runs render at the same vertical position. This affects every
term with a formula in its name (~15 terms) and every formula in
body text.

## Approach

Extend the content model and renderer:

1. `Content::InlineRun` gains optional `baseline_shift: :sub | :sup | nil`
   and `font_size_scale: Float` (default 1.0). Subscript runs use
   ~0.7x font size and shift down ~0.2em; superscript ~0.7x and
   shift up ~0.4em.

2. `Style::Definition` gains `baseline_shift` and `font_size_scale`
   attributes. New style IDs: `:subscript`, `:superscript` (children
   of :body with appropriate shifts).

3. Adapter's `walk_math_text` detects MathML structure:
   - `<msub><mi>D</mi><mtext>min</mtext></msub>` → InlineRun("D") +
     InlineRun("min", baseline_shift: :sub)
   - `<msup>` → baseline_shift: :sup
   - `<msubsup>` → both

4. Renderer's `render_line_runs` positions subscript/superscript
   runs at shifted baselines with scaled font size.

## Done-When

- [ ] `Content::InlineRun` carries `baseline_shift` and `font_size_scale`.
- [ ] MathML `<msub>`/`<msup>` produce subscript/superscript runs.
- [ ] "D_min" renders with "min" as subscript (smaller, shifted down).
- [ ] Specs cover: subscript, superscript, nested sub+sup.
- [ ] No regression in existing text rendering.

## Implementation

- `Content::InlineRun` gains `baseline_shift` (:sub/:sup/nil) and `font_size_scale` (default 1.0). Constants BASELINE_NORMAL/SUB/SUP.
- Layout-level `Arroolio::InlineRun` mirrors these attributes; `width()` scales by font_size_scale.
- `InlineRunCollector#walk_math_text` detects `<msub>`, `<msup>`, `<msubsup>` — first child renders normally, subsequent children get baseline_shift + 0.7x font size.
- `Renderer::Pdf#baseline_position_for` shifts sub down 0.2em, sup up 0.4em, with scaled font size.
- `FlowBuilder#text_paragraph_from_content` and `list_flowable` propagate baseline_shift from Content to layout InlineRun.
- 9 specs in `spec/arrolio/inline_run_baseline_spec.rb`.
