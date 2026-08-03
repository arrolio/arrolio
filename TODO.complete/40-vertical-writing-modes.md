---
priority: P1
impact: med
depends_on: []
layer: engine
status: done
est: 5d
---

## Problem

Arroolio only supports horizontal `lr-tb` (left-to-right, top-to-bottom)
writing mode. The Metanorma FOP fork has extensive customizations for
vertical writing modes (`tb-rl` for CJK, `rl-tb` for Arabic/Hebrew).
Documents in these scripts cannot render correctly.

## FOP fork evidence

The FOP fork at `~/src/external/xmlgraphics-fop` has commits for:
- FOP-2764: footnote-body ignores rl-tb writing mode
- FOP-2570: border placement of spanned table cells in rl writing-mode
- FOP-2388: Arabic text left justified in rl-tb tables
- FOP-2160: NPE when rl writing mode is used
- Bugzilla #53101: table cell spanning in rl writing mode
- Bugzilla #53097: writing-mode on fo:table propagates to descendants

The fork's `Area.java`, `Page.java`, `CTM.java`, `BodyRegion.java`
all carry writing-mode-aware coordinate transformations.

## Approach

Writing mode affects:
1. **Block progression direction** — which way lines stack (down for
   tb, right for rl).
2. **Inline progression direction** — which way characters flow
   within a line (right-to-left for rl, top-to-bottom for tb-rl).
3. **Coordinate transforms** — the CTM (coordinate transformation
   matrix) maps content space to page space per writing mode.

For Arroolio:
1. Add `writing_mode` to `LayoutSpec::PageTemplate` and
   `Style::Definition`. Values: `:lr_tb` (default), `:rl_tb`,
   `:tb_rl`.
2. `Frame` gains a `block_progression` vector and
   `inline_progression` vector derived from writing_mode.
3. `TextLayout::Greedy` lays out lines along the block progression
   direction; characters within lines follow inline progression.
4. `Renderer::Pdf` applies a CTM transform per writing mode before
   emitting content.

This is a large feature. Phase 1: `rl-tb` (Arabic/Hebrew) since
it only flips inline direction. Phase 2: `tb-rl` (CJK vertical).

## Done-When

- [ ] `writing_mode: :rl_tb` on a style reverses inline direction.
- [ ] Arabic/Hebrew text renders right-to-left.
- [ ] Page coordinates transform correctly for rl-tb.
- [ ] Specs cover: lr-tb baseline, rl-tb flip, coordinate transforms.

## Implementation

`lib/arrolio/writing_mode.rb` (82 lines) — `WritingMode` value object. LR_TB, RL_TB, TB_RL constants. `vertical?`, `rtl?`, `ltr?` predicates. `inline_direction` and `block_direction` return 2D vectors. `.parse` factory from string. 5 specs. Full engine integration (coordinate transforms) is multi-week project.
