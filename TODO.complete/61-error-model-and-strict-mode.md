---
priority: P1
impact: high
depends_on: [50]
layer: engine
status: done
est: 2d
---

## Problem

The pipeline swallowed many errors silently:

- Missing font file → warned and fell back to Helvetica, producing
  visually wrong output for CJK or specialist fonts without telling
  the caller anything was wrong.
- No `strict:` mode for callers who want to fail loud rather than
  render broken output.
- `RenderError` was a bare class with no metadata.

## Approach

1. **`RenderError` typed metadata**: now carries `missing_fonts:` —
   an Array of `[name, path]` pairs.
2. **`FontMetrics::Registry.register_ttf_all(paths, strict:)`**: when
   `strict: true`, raises `Arroolio::RenderError` listing every
   required font whose path does not exist on disk.
3. **`ConfigDrivenPipeline.new(strict: true)`**: forwards to the
   registry, so the render fails at the font-registration step before
   producing any output rather than midway through.
4. **`ConfigDrivenPipeline.render(..., strict: true)`**: same at the
   class level.
5. **`pipeline.strict` reader** for inspection.

## Done-When

- [x] `Arroolio::RenderError` carries structured `missing_fonts:` metadata
- [x] `FontMetrics::Registry.register_ttf_all` accepts `strict:` kwarg
- [x] `ConfigDrivenPipeline` accepts `strict:` kwarg and forwards it
- [x] Default behavior (strict: false) is unchanged — backwards compatible
- [x] Specs cover: strict mode raises with missing_fonts; non-strict
      mode does not raise; strict reader works

## Verification

- `spec/arrolio/strict_mode_spec.rb` (4 specs)
- `bundle exec rake` is green
- Real OIML fixture still renders 28 pages with `strict: false`

## Future strict-mode expansions

The pattern is established. Future strict checks can be added with
minimal ceremony:

- Missing image: `RenderError(missing_images:)` when an `<image src=>`
  cannot be resolved and `strict:` is true.
- Unknown style: `LayoutSpecError(unknown_style:)` when a style_id
  referenced by the flow builder isn't in the layout_spec's registry.
- Adapter selector gap: `AdapterError(missing_selector:)` when the
  adapter needs a selector that the flavor didn't declare.

These are individually TODO-worthy but follow the same template.
