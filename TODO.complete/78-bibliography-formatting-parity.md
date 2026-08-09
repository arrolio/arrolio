---
priority: P2
impact: low
depends_on: [70]
layer: adapter
status: done
est: 1d
---

## Problem

Bibliography page renders content but with wrong formatting. The
reference uses numbered references `[1]`, `[2]` with hanging indent
so wrap lines align under the citation text, not under the tag.

A separate bug in `extract_bibliography` compounded this: the
`each_child` loop pushed Arrays into items without flattening,
hiding all bibliography items from the flow builder.

## Status (2026-08-06)

- [x] **`extract_bibliography` now flattens** — uses `items.concat`
      instead of `items <<`.
- [x] **`bibliography_item_flowable` emits a TextFlowable with
      hanging_indent** equal to the marker width. First line: tag
      flush left + citation starts after marker. Wrap lines:
      indented by marker_w so they align under the citation text.
- [x] **TextFlowable supports hanging_indent** — new attribute
      reduces effective width for layout and signals the renderer
      to offset wrap lines.

## Verification

Page 28 bibliography page now renders entries with proper hanging
indent:
```
[1] OIML V 1:2013, International Vocabulary of Terms in Legal
    Metrology (VIML)
[2] OIML V 2-200:2012, International Vocabulary of Metrology —
    Basic and General Concepts and Associated Terms (VIM)
```

## Still pending

- **4pt gap between entries** — current `:bibitem` style has
  `margin_top: 4`, `margin_bottom: 4` but it's not visible in the
  extracted output.
- **Bibliography section heading style** — heading renders but
  may not use the exact level-1 style.

## Done-When

- [x] Bibliography entries render as single paragraphs
- [x] All entries appear in output (was 0 due to concat bug)
- [x] Hanging indent so wrap lines align with text start
- [ ] 4pt gap between entries (visual only — text diff unaffected)
- [ ] Page 28 similarity > 85% (currently ~50% due to body drift)

## Measurement

`bundle exec rake parity:check` — page 28 bibliography page now
renders all 12 entries with proper hanging indent.
