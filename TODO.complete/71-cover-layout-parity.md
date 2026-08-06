---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

Page 1 (cover) sits at **48.0%** similarity. The reference cover
uses a complex SVG-based layout that the current flat text stack
can't model.

## Status (2026-08-06)

Three foundation primitives shipped in this PR:

- **`Flowables::PositionedBlock`** — absolute-positioned container
  for the title border-box, organisation footer block, and rotated
  docidentifier.
- **`Flowables::RotatedText`** — text rendered at a fixed angle
  around its baseline. Renderer applies a rotated Tm matrix.
- **`Style::Definition#text_transform`** — `[sx, sy]` pair that
  the renderer applies as a scale matrix for condensed text (the
  SVG `scale(0.82, 1)` effect on cover header text).

Existing primitives that compose:
- **`Flowables::TwoColumnBlock`** — already exists, handles the
  cover header (doctype left + docidentifier right) and the
  organisation footer (logo left + names right).

## Still pending

The full cover schema migration in `flow_rules.yml`. Currently
the cover is a flat list of `cover_content:` entries. The new
schema will be a tree of positioned blocks:

```yaml
cover_layout:
  type: positioned
  blocks:
    - type: two_column
      top: 0
      columns:
        - width: 50%
          blocks:
            - type: text
              source: "{{doctype}}"
              font: "Jost"
              font_size: 19
              text_transform: [0.82, 1.0]
        - width: 50%
          blocks:
            - type: text
              source: "{{docidentifier}}"
              font: "Jost SemiBold"
              font_size: 28
              text_transform: [0.82, 1.0]
    - type: bordered_block
      top: 65mm
      width: 119mm
      ...
```

`GenericFlowBuilder#build_cover_content` needs to detect the new
`cover_layout` schema and emit the corresponding flowable tree;
fall back to the flat-list behavior when only `cover_content` is
present.

## Done-When

- [x] `Flowables::PositionedBlock` exists with specs
- [x] `Flowables::RotatedText` exists with specs
- [x] `Style::Definition#text_transform` field exists
- [x] Renderer dispatches :rotated_text kind
- [ ] `flow_rules.yml` migrated to `cover_layout` schema
- [ ] `build_cover_content` parses the new schema
- [ ] Renderer applies `text_transform` scale via Tm
- [ ] Page 1 similarity > 60%

## Expected improvement

Page 1 from 48% to ~75% (text already matches; layout needs the
positioned blocks). +1% overall.
