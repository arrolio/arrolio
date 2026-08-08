---
priority: P0
impact: high
depends_on: [70]
layer: flowable
status: in_progress
est: 5d
---

## Problem

Page 1 (cover) at 48%. Reference cover uses SVG-scaled two-column
header, bordered title box, organisation footer, and rotated
vertical docidentifier. Our cover is a flat text stack.

## Status (2026-08-08)

Three foundation primitives shipped:

- [x] **`Flowables::PositionedBlock`** — absolute-positioned
      container with top/left/width/height. Zero flow height.
      4 specs.
- [x] **`Flowables::RotatedText`** — text at a fixed angle.
      Renderer builds rotated Tm matrix. 3 specs.
- [x] **`Style::Definition#text_transform`** — `[sx, sy]` scale
      pair for the condensed-text effect.
- [x] **`Flowables::TwoColumnBlock`** — already existed for
      left/right column layout.

## Still pending

- [ ] **`cover_layout` schema migration** in flow_rules.yml
- [ ] **`build_cover_content`** parser for the new schema
- [ ] **Renderer applies `text_transform` scale** via Tm matrix
- [ ] **Bordered title box** via PositionedBlock + rect border
- [ ] **Page 1 similarity > 60%**

## Done-When

- [x] PositionedBlock primitive
- [x] RotatedText primitive
- [x] text_transform field
- [x] Renderer dispatches :rotated_text
- [ ] cover_layout schema in flow_rules.yml
- [ ] Page 1 > 60%
