---
priority: P0
phase: 3
depends_on: [11]
layer: text
est: 1d
status: in_progress
---

## Problem

The line breakers emit lists of `Line` objects. Each `Line` carries
the placed runs (with x-offsets), the line width, and the alignment.
The renderer needs these to know exactly where to draw each run.

## Approach

Files:

- `lib/arrolio/text_layout/line.rb` — `Line` value object:
  - `placed_runs` — Array of `PlacedRun` (run + x_offset within line).
  - `width` — actual content width of the line.
  - `max_width` — target width (for alignment reference).
  - `align` — `:left`, `:right`, `:center`, `:justify`.
  - `x_offset` — line's left-edge offset based on alignment:
    - left: 0
    - right: `max_width - width`
    - center: `(max_width - width) / 2`
  - `justify_stretch` — extra width per word gap for justify alignment
    (last line of a paragraph is never justified).
- `lib/arrolio/text_layout/placed_run.rb` — `Struct.new(:run,
  :x_offset, keyword_init: true)`.

Both breakers (Greedy, KnuthPlass) produce `Line[]` via the same code
path — extract shared line-building into a private helper.

## Done-When

- [ ] `Line#x_offset` for centered alignment matches
      `(max_width - width) / 2`.
- [ ] `Line#justify_stretch` is 0 for the last line in a paragraph.
- [ ] `Line#justify_stretch` evenly distributes slack across word gaps
      for non-last lines.
- [ ] A renderer that consumes `Line#placed_runs` can place every run
      at the correct x position.
