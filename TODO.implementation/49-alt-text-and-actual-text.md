---
priority: P2
phase: 15
depends_on: [48, 33]
layer: a11y
est: 1d
status: pending
---

## Problem

PDF/UA mandates alt text on every image (`/Alt` on the Figure
structure element) and supports `/ActualText` on any element (for
cases where the visible text isn't the accessible text — e.g.
mathematical equations rendered as glyphs).

## Approach

Extend `Arrolio::Content::Image` (TODO 02) with `alt` (String).
Extend `Arrolio::Flowables::ImageFlowable` (TODO 33) to propagate
`alt` to the PlacedBox.

Extend `Arrolio::Output::PlacedBox` with `alt_text` and
`actual_text` fields.

Renderer integration (TODO 48 StructElement):
- When emitting a `<Figure>` StructElement for an image, include
  `/Alt (alt text)` if `alt_text` is set.
- When emitting any StructElement, include `/ActualText` if the
  PlacedBox carries it.

Validation:
- A `Content::Image` without `alt` produces a warning (configurable:
  error in strict mode).
- A `Content::Equation` without `actual_text` produces a warning.

## Done-When

- [ ] Image with `alt: "Diagram of the system"` emits `/Alt` on its
      Figure element.
- [ ] Equation with `actual_text: "E = mc^2"` emits `/ActualText`.
- [ ] Missing alt text raises a warning (or error in strict mode).
- [ ] Screen reader reads the alt text when navigating to an image.
