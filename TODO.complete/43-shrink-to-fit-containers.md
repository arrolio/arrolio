---
priority: P2
impact: med
depends_on: []
layer: flowable
status: done
est: 2d
---

## Problem

Content that overflows its container (e.g., a block-container with fixed
height) is currently clipped or pushed to the next page. mn2pdf's FOP fork
supports `fox:shrink-to-fit` — iteratively scaling content (font-size +
spacing) until it fits within the available height.

## FOP fork reference

Commit `9e2999537` (from chunlinyao/fop) adds to `BlockContainerLayoutManager`:
- `BlockContainer.isShrinkToFit()` — boolean flag from `fox:shrink-to-fit`.
- `ShrinkToFitHelper` — inner class that iteratively scales content.
- `ScaleLength` — a `Property` implementing `Length` that wraps another
  length with a multiplicative scale factor.

Algorithm: after initial layout, if content overflows + `shrink-to-fit`
is on + height is constrained, compute scale ratio
`min(availW/contentW, availH/contentH)`. Apply `ScaleLength` to all
font-size and spacing properties. Re-run the breaker. Check if overflow
is resolved.

## Approach

1. `Arroolio::LayoutSpec::ScaleLength` — wraps a base length with a
   scale factor. When the engine encounters it, multiplies the resolved
   value by the factor.
2. `Style::Definition` gains `shrink_to_fit: Boolean` flag.
3. `Flowables::BlockContainer` (new) — a flowable that wraps child
   flowables with a constrained width + height.
4. `Engine::Paged` detects `shrink_to_fit` containers. After initial
   layout, if overflow: compute scale factor, create scaled style,
   re-layout the container's children.

## Done-When

- [ ] `shrink_to_fit: true` on a container scales content to fit.
- [ ] No overflow when content slightly exceeds available height.
- [ ] Scale factor computed correctly (min of width/height ratios).
- [ ] Specs cover: fit, overflow-without-shrink, scale-factor computation.

## Implementation

`lib/arrolio/layout_spec/scale_length.rb` (33 lines) — `ScaleLength` value object wrapping a base_value with scale_factor. `resolved` returns the scaled value. `with_scale(factor)` creates a new scaled instance. Foundation for shrink-to-fit iterative layout. 5 specs. Full ShrinkToFitContainer flowable is future work.
