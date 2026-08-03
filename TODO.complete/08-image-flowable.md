---
priority: P0
impact: med
depends_on: []
layer: flowable
status: done
est: 1d
---

## Problem

Figures in OIML (figure-1.svg, figure-2.svg) are not rendered —
adapter extracts just the figure caption. Reference embeds the
image (PNG or SVG-as-Form-XObject) sized to fit the column.

## Approach

File: `lib/arrolio/flowables/image_flowable.rb`

```ruby
class ImageFlowable < Flowable
  def initialize(src, width: nil, height: nil, alt: nil)
  def natural_size  # read from PNG/JPEG header
  def height(width, context)  # preserve aspect ratio
  def emit(x, y, width, context)
    # register with document.images, emit InvokeXObject via cm operator
  end
end
```

Update Adapter to emit ImageFlowable for `<image>` elements inside
`<figure>`. Resolution: relative paths resolved against the source
XML's directory.

## Done-When

- [ ] Figure 1 (Typical components in a weighing instrument) renders
      on page 6 of the OIML output.
- [ ] Image scaled to fit the body column width (≤ 110mm).
- [ ] Specs cover: PNG loading, aspect preservation, missing-file
      fallback, alt-text embedding (for PDF/UA later).

## Implementation

`lib/arrolio/flowables/image_flowable.rb` + `lib/arrolio/content/image.rb`. SVG rasterized to PNG via rsvg-convert (cached by MD5). Image registration deferred to render pass.
