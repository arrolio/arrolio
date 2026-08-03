---
priority: P1
phase: 4
depends_on: [10]
layer: knuth
est: 2d
status: pending
---

## Problem

FOP's greatest insight: one algorithm (Knuth-Plass dynamic
programming) handles line breaks, page breaks, column balancing, and
table row distribution alike. The universal input is the Knuth element
triple: Box (fixed-size content), Glue (inter-content with
stretch/shrink), Penalty (break cost). My current pdfrb has this
implicit inside TextLayout only.

## Approach

Files under `lib/arrolio/knuth/`:

- `element.rb` — base class. Each element has a `width` (Float) and a
  `flagged?` boolean (for penalty/forced breaks).
- `box.rb` — content with fixed size: `Box.new(width: 30.0, content_ref)`.
- `glue.rb` — inter-content: `Glue.new(width:, stretch:, shrink:)`.
- `penalty.rb` — break cost: `Penalty.new(width:, penalty:, flagged:)`.
  Special values:
  - `Penalty::INFINITE` (no break here)
  - `Penalty::FORCED` (must break here)

File: `lib/arrolio/breaker.rb`.

```ruby
class Arrolio::Breaker
  def initialize(elements, target_width:, tolerance: 1.0)
  def break -> [BreakPoint, BreakPoint, ...]
end
```

Algorithm (Knuth-Plass DP):
1. Active set starts with node 0 at total cost 0.
2. For each feasible break point, compute badness from preceding
   active nodes; pick the minimum-cost predecessor.
3. Returns the chosen break-point sequence.

A `BreakPoint` references the element index and the predecessor.

## Done-When

- [ ] Knuth elements round-trip through serialisation.
- [ ] `Breaker` on a synthetic Box-Glue-Penalty sequence produces
      optimal breaks matching a hand-computed result.
- [ ] `Penalty::FORCED` always breaks.
- [ ] `Penalty::INFINITE` never breaks.
- [ ] Specs cover under-full, over-full, and exact-fit cases.
