---
priority: P0
phase: 5
depends_on: [16]
layer: flowable
est: 1d
status: in_progress
---

## Problem

Need two simple flowables: vertical `Spacer` (reserve empty space) and
`PageBreak` (force the engine to advance to the next page before
continuing).

## Approach

File: `lib/arrolio/flowables/spacer.rb`.

```ruby
class Arrolio::Flowables::Spacer < Arrolio::Flowable
  def initialize(amount)
  def height(width, context) = amount
  def render(*); amount; end
  def splittable?; true; end
  def do_split(width, remaining_height, context)
    # If amount fits, return self. Else split into two spacers.
  end
end
```

File: `lib/arrolio/flowables/page_break.rb`.

```ruby
class Arrolio::Flowables::PageBreak < Arrolio::Flowable
  def height(*); 0.0; end
  def render(*); 0.0; end
  def page_break_after?; true; end   # engine recognises this
end
```

Engine treats `PageBreak` as a sentinel: instead of placing it, it
advances to a new page. Both flowables are zero-cost on render.

## Done-When

- [ ] `Spacer.new(50).height(100, ctx) == 50`.
- [ ] `Spacer.new(100).do_split(100, 30, ctx)` returns
      `[Spacer(30), Spacer(70)]`.
- [ ] `PageBreak.new.page_break_after? == true`.
- [ ] Engine consumes `PageBreak` without rendering it.
- [ ] Specs cover both.
