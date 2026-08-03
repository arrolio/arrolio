---
priority: P1
phase: 11
depends_on: [10]
layer: inline
est: 1d
status: pending
---

## Problem

A paragraph is a list of InlineRuns. Authoring those runs by hand is
tedious. The InlineBuilder DSL lets authors compose runs declaratively:
`.text("Hello ")`, `.bold("world")`, `.color(:red) { .text("apple") }`.
Style spans (bold, italic, colour) become first-class.

## Approach

Files:

- `lib/arrolio/inline_builder.rb` — builder DSL on top of Style::Diff:

```ruby
builder = Arrolio::InlineBuilder.new(base_style)
builder.text("Hello ")
builder.bold("world")            # creates run with bold-weight style
builder.italic(" and italic")
builder.color(:red) { |b| b.text(" apple") }
builder.link("Click here", ref_id: "ch1")
runs = builder.runs   # => [Run("Hello ", base), Run("world", base+bold), ...]
```

- `lib/arrolio/style/diff.rb` (extended from TODO 04) — given a base
  Definition + overrides hash, produces a new Definition. Used by
  InlineBuilder's `bold`/`italic`/`color` helpers.

Helpers:
- `bold(str)` / `bold { ... }` — `font_weight: "bold"`.
- `italic(str)` / `italic { ... }` — `font_style: "italic"`.
- `color(c, str)` / `color(c) { ... }` — `fill_color: c`.
- `size(n, str)` / `size(n) { ... }` — `font_size: n`.
- `font(name, str)` — `font_name: name`.

## Done-When

- [ ] `InlineBuilder.new(style).text("a").bold("b").runs.length == 2`.
- [ ] Bold helper sets `font_weight: "bold"` on the run's style.
- [ ] Color helper overrides only `fill_color`, keeps other props.
- [ ] Nested helpers compose (`.bold { .color(:red) { .text("x") } }`).
- [ ] Link helper creates a HyperlinkRun (TODO 37).
