---
priority: P0
phase: 5
depends_on: [04, 13]
layer: flowable
est: 2d
status: in_progress
---

## Problem

The page-flow engine places "flowables" — paragraphs, tables, images,
spacers, page breaks — into frames, splitting and advancing pages as
needed. The Flowable base class defines the contract every flowable
must satisfy; Frame tracks remaining space.

## Approach

Files:

- `lib/arrolio/flowable.rb` — abstract base.
  - `height(width, context)` → Float: natural height at this width.
  - `render(canvas, x, y, width, context)` → Float: actual height
    consumed (may differ from `height` if rendering adjusts).
  - `splittable?` — true if the flowable supports `split`.
  - `keep_together?` — true if it must not be split.
  - `page_break_before?`, `page_break_after?` — bool flags from style.
  - `split(width, remaining_height, context)` → `[head, tail]` where
    head fits in remaining_height, tail is the rest (or nil).
  - `do_split(width, remaining_height, context)` — subclass hook.
  - Default `split`: if `height <= remaining_height`, `[self, nil]`;
    if not splittable and not keep_together, render whole `[self, nil]`;
    if keep_together, `[nil, self]`.

- `lib/arrolio/frame.rb` — rectangular region tracking consumed space.
  - `x`, `y`, `width`, `height`, `consumed`.
  - `remaining_height`, `full?`, `consume!(h)`, `cursor_y`, `clone_empty`.
  - `available_width_at(y)` — for text wrap (FloatRegistry hook).

- `lib/arrolio/float_registry.rb` — tracks floated boxes for wrap;
  `available_width_at(frame_x, full_width, y)` returns
  `[x_start, available_width]`.

## Done-When

- [ ] `Flowable.new.height(100, ctx)` raises `NotImplementedError`.
- [ ] A subclass that returns height 50 and renders 50 actually does.
- [ ] `Frame.new(x: 0, y: 0, width: 100, height: 200).consume!(50)`
      leaves `remaining_height == 150`.
- [ ] `FloatRegistry` with a left-floated image reduces
      `available_width_at` on the floated y-range.
- [ ] Specs cover the abstract contract + 1 concrete subclass.
