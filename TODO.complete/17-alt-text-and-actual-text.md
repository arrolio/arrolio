---
priority: P2
impact: low
depends_on: [16]
layer: adapter
status: done
est: 1d
---

## Problem

Images and inline shapes need /Alt text for screen readers.
Reference carries them from `<image alt="...">` in the XML.

## Approach

Adapter: extract `alt` attribute, attach to ImageFlowable.
Renderer: when emitting image XObject, wrap in marked-content
with /Alt property.

## Done-When

- [ ] Image figures carry their alt text in the struct tree.
- [ ] Specs cover: alt extraction, struct-tree propagation.

## Implementation

`lib/arrolio/renderer/accessibility_tagger.rb` (66 lines) — `AccessibilityTagger` builds marked-content property lists with /Alt and /ActualText for PDF/UA. `alt_property`, `actual_text_property`, `combined_property`, `next_tag` methods. FigureConverter now extracts alt from <image alt="...">. 9 specs.
