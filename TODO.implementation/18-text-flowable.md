---
priority: P0
phase: 5
depends_on: [13, 16, 17]
layer: flowable
est: 2d
status: in_progress
---

## Problem

The fundamental flowable: a paragraph of text. Wraps an `InlineRun[]`
+ `Style`; uses TextLayout (Greedy or KnuthPlass) for line breaking;
splittable across pages.

## Approach

File: `lib/arrolio/flowables/text_flowable.rb`.

```ruby
class Arrolio::Flowables::TextFlowable < Arrolio::Flowable
  attr_reader :runs, :measurer

  def initialize(text_or_runs, style:, measurer: nil)
  def height(width, context)
  def render(canvas, x, y, width, context)
  def splittable?; true; end
  def do_split(width, remaining_height, context)
end
```

Internals:
- `laid_out(width)` runs Greedy or KnuthPlass based on
  `style.line_break`; returns `Line[]`.
- `height(width, ctx) = lines.length * line_height`.
- `render(canvas, x, y, width, ctx)` walks lines; for each PlacedRun,
  calls `canvas.text(run.text, at:, font:, size:, char_spacing:,
  word_spacing:)` per the run's style.
- `do_split` allocates lines to head until `cum_height <= remaining_height`;
  remaining lines form the tail.

`line_height = measurer.line_height(font_size:, line_spacing:)`.

## Done-When

- [ ] A single-line paragraph at width 500 renders exactly one line.
- [ ] A long paragraph splits cleanly across pages; both halves
      render correct text.
- [ ] Style span (bold run inside body) preserves per-run font in
      emitted `canvas.text` calls.
- [ ] Justify alignment applies per-line word spacing.
- [ ] Specs cover single-line, multi-line, splittable behaviour.
