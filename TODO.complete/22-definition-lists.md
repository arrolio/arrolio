---
priority: P1
impact: low
depends_on: []
layer: render
status: done
est: 1d
---

## Problem

`<dl>` definition lists (term + definition pairs) render as flat
text. Reference uses aligned term/definition columns with proper
wrapping.

## Approach

Reuse `ListFlowable` infrastructure (TODO 05) with `:definition`
kind:

- Marker column = term (bold)
- Body column = definition (regular)
- Hanging indent so wrapped definition lines align

Per oiml.xsl: `dt-block` style has `margin-bottom: 3pt`.

## Done-When

- [ ] Definitions section in section 3 (Terminology) renders with
      bold terms + indented definitions matching reference.
- [ ] Specs cover: term extraction, definition body wrapping,
      hanging indent.

## Implementation

Adapter `convert_def_list` — dt/dd pairs with em-dash separator, no stray bullet markers.
