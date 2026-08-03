---
priority: P1
impact: med
depends_on: [30]
layer: adapter
status: done
est: 1d
---

## Problem

`Arroolio::Oiml::Pipeline` is a class method on `Pipeline` that
hardcodes:
- `Oiml::LayoutSpecLoader.load` (no path param)
- Specific image base directories
- `Renderer::Pdf` as the only renderer
- Logo path discovery

There's no way to:
- Use a different layout spec
- Point at a different input file
- Use a different renderer
- Suppress the logo
- Configure logging level

## Approach

Introduce `Arroolio::Oiml::Config` as a value object:

```ruby
Config = Struct.new(
  :layout_spec_path,    # default: data/oiml/layout_spec.yml
  :image_base_dirs,     # default: derived from input_path
  :renderer_class,      # default: Renderer::Pdf
  :logo_path,           # default: auto-discover, nil to suppress
  :log_level,           # default: :warn
  :metadata,            # default: extracted from XML
  keyword_init: true
)
```

`Pipeline.render(xml, io:, config:)` takes a Config. Default
factory method `Config.for_oiml(input_path)` produces sensible
defaults. The exe/oiml2pdf CLI constructs a Config from CLI args.

## Done-When

- [ ] `Pipeline.render` accepts a Config parameter.
- [ ] No hardcoded paths in Pipeline.
- [ ] `exe/oiml2pdf` builds Config from command-line args.
- [ ] Specs cover: custom renderer, custom layout, logo suppression.

## Implementation

`lib/arrolio/oiml/config.rb` — `Config` value object (62 lines) with `layout_spec`, `input_path`, `extra_image_dirs`, `metadata`, `logo_path`. `asset_resolver` builds the resolver. `DEFAULT_IMAGE_DIRS` constant. `Pipeline.render_with(xml:, io:, config:)` is the new injection-friendly entry point. 10 specs in `spec/arrolio/oiml/config_spec.rb`.
