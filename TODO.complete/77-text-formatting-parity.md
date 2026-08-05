---
priority: P2
impact: low
depends_on: [70, 79]
layer: adapter
status: in_progress
est: 1d
---

## Problem

Section number formatting and several inline-formatting details
differ from the reference:

- Reference: section "2.1" rendered with the autonum "2", delim
  ".", autonum "1" sequence preserved (fixed in 2026-08-05 commit
  via `extract_from_heading` delimiter inclusion).
- Reference: bullet markers are `■` (filled square) with specific
  indent; ours uses the same marker but indent differs.
- Reference: note labels are "NOTE 1 —" with an em-dash; ours
  uses "NOTE 1 " with a space.
- Reference: sub/superscript rendering (subscript `<sub>`,
  superscript `<sup>`) — InlineRun already carries `baseline_shift`
  and `font_size_scale`; the adapter needs to set them on `<sub>`
  / `<sup>` runs.
- Reference: hyperlink styling (underlined, blue) — `link` style
  exists; the adapter sets `href:` but doesn't apply underline.

These small differences compound across every page.

## Done-When (already fixed)

- [x] Section number "2.1" extracts as "2.1" not "21" (delimiter
      included via autonum-delim + caption-label class match)

## Done-When (still pending)

- [ ] Note labels have the correct suffix (em-dash "—" or colon)
- [ ] List bullet indent matches reference
- [ ] `<sub>` produces `baseline_shift: :sub, font_size_scale: 0.7`
- [ ] `<sup>` produces `baseline_shift: :sup, font_size_scale: 0.7`
- [ ] Hyperlinks render underlined (renderer needs underline
      support, or `link` style needs `underline: true` field)

## Approach

1. **Note label format**: look up the XSL's `note-name-style` —
   it appends an em-dash via `<xsl:text>—</xsl:text>` after the
   `<fmt-name>`. Update `note_flowable` in `GenericFlowBuilder`
   to append `" —"` (or use the layout_spec to make it
   configurable per flavor).

2. **Sub/sup**: extend `collect_inline_runs` to detect `<sub>` /
   `<sup>` (via `inline_styles` mapping already in standoc.yml)
   and set `baseline_shift` and `font_size_scale` on the produced
   `Content::InlineRun`.

3. **Hyperlink underline**: extend `Style::Definition` with an
   `underline` boolean; renderer emits `/UL true` in the text
   state before drawing the run.

## Expected improvement

Estimated 2–3% overall similarity (text-level formatting matches
more closely on every body page).

## Current state (2026-08-05)

Section delimiter fixed. Note labels, sub/sup, and underline still
pending.
