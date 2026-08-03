---
priority: P1
phase: 10
depends_on: [16]
layer: media
est: 2d
status: in_progress
---

## Problem

Need a real ImageFlowable (not the placeholder from the FO spike).
It loads the image via Pdfrb, scales to target size, optionally
aligns (left/center/right), and is not splittable. Wraps it as a
Flowable that the engine places into a frame.

## Approach

File: `lib/arrolio/flowables/image_flowable.rb`.

```ruby
class Arrolio::Flowables::ImageFlowable < Arrolio::Flowable
  def initialize(src, width: nil, height: nil, max_width: nil,
                 max_height: nil, align: :left)
  def natural_size -> [w, h]   # cached after first measurement
  def height(target_width, context)
  def render(canvas, x, y, width, context)
  def splittable?; false; end
end
```

Internals:
- On first `natural_size` call, ask Pdfrb to load the image
  (Pdfrb::ImageLoader dispatches by format: JPEG, PNG, PDF page).
  Cache the loaded image reference + its pixel dimensions.
- Scaling rules:
  - Both `width:` and `height:` explicit → use as-is (may distort).
  - Only `width:` → `height = width * natural_h / natural_w`.
  - Only `height:` → symmetric.
  - Neither, but `max_width:` / `max_height:` → scale down to fit,
    never up.
  - Neither → use natural size.

Render:
- `name = context.document.images.add(src)` (Pdfrb handles caching).
- `canvas.image(name, at: [x + align_offset, y], width:, height:)`.

Alignment offset: depends on `align` (:left = 0, :center = (width -
img_w) / 2, :right = width - img_w).

## Done-When

- [ ] An 800×600 image with `width: 200` renders at 200×150.
- [ ] Same image with `max_width: 1000` renders at natural size.
- [ ] `align: :center` horizontally centres the image.
- [ ] Image is not splittable; if it doesn't fit, engine advances.
- [ ] PNG with alpha (SMask) renders correctly.
- [ ] JPEG passthrough works (no re-encode).
- [ ] Round-trip: rendered PDF re-read has expected /XObject.
