---
priority: P0
phase: 3
depends_on: [10]
layer: text
est: 1d
status: in_progress
---

## Problem

The simplest correct line breaker: first-fit word wrap. Walk runs
left-to-right, accumulate words, emit a line when the next word would
exceed the target width. FOP's default. Linear time, fast.

## Approach

File: `lib/arrolio/text_layout/greedy.rb`.

```ruby
class Arrolio::TextLayout::Greedy
  def initialize(runs, measurer:, width:, align: :left)
  def layout -> [Line, Line, ...]
end
```

Algorithm:
1. Enumerate break opportunities.
2. Track `line_start` index into the opportunity list.
3. For each subsequent opportunity, compute `line_width = opp.width_before
   - opps[line_start].width_before`.
4. If `line_width > target_width` and we have at least one opportunity
   on this line, emit a line ending at the previous opportunity; reset
   `line_start`.
5. Force-break at `:forced` opportunities.
6. At end, emit the trailing line.

Output: list of `Line` objects (TODO 13). This TODO builds Lines
without alignment offsets; TODO 13 adds offsets.

## Done-When

- [ ] A single short word on one line: `"Hello"` at width 500 → 1 line.
- [ ] Long text wraps to multiple lines; no line exceeds target width
      except for unbreakable words.
- [ ] Forced newline breaks the line.
- [ ] Style change at a space does not produce a spurious line break.
- [ ] Per-line `width` is correct (matches sum of placed run widths).
