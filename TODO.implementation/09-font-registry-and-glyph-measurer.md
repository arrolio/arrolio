---
priority: P0
phase: 2
depends_on: [07, 08]
layer: metrics
est: 1d
status: in_progress
---

## Problem

Engine and TextLayout need one stable interface for "ask the font about
glyph metrics" regardless of whether the font is AFM-backed (standard
Type1) or TTF-backed. Plus a high-level measurer that combines metrics
with PDF's `Tc`/`Tw` operator semantics.

## Approach

Files:

- `lib/arrolio/font_metrics/interface.rb` — module documenting the
  contract every metrics class implements: `units_per_em`,
  `advance_width(char)`, `width_of_string(str, font_size:)`,
  `ascender(font_size:)`, `descender(font_size:)`,
  `cap_height(font_size:)`, `x_height(font_size:)`,
  `line_height(font_size:, line_spacing:)`.
- `lib/arrolio/font_metrics/registry.rb` — singleton; maps font name
  to a metrics instance; memoises; supports `register_ttf(name, path)`.
- `lib/arrolio/glyph_measurer.rb` — high-level facade over a metrics
  instance. Methods:
  - `width_of_string(str, font_size:)` — direct.
  - `width_of_run(str, font_size:, character_spacing:, word_spacing:)`
    — adds `character_spacing * (chars - 1)` and `word_spacing * words`.
  - `line_height(font_size:, line_spacing:)`.
  - `space_width(font_size:)`.
  - `available?` — false when no metrics loaded (falls back to 0.5em
    estimate to keep layout usable).

## Done-When

- [ ] `Registry["Helvetica"]` returns an `AfmMetrics` instance,
      memoised across calls.
- [ ] `Registry["Unknown"]` returns `nil`.
- [ ] After `Registry.register_ttf("MyFont", "/path/x.ttf")`,
      `Registry["MyFont"]` returns a `TrueTypeMetrics`.
- [ ] `GlyphMeasurer.new(font_name: "Helvetica").width_of_run("a b c",
      font_size: 12, character_spacing: 1, word_spacing: 2)` matches
      the PDF spec formula.
- [ ] Specs cover both AFM and TTF paths through GlyphMeasurer.
