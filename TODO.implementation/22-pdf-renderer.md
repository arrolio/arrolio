---
priority: P0
phase: 6
depends_on: [21]
layer: render
est: 3d
status: in_progress
---

## Problem

The PDF renderer walks `Output::Page[]` and emits PDF bytes via
Pdfrb. This is where Arrolio stops being medium-neutral and becomes
PDF-specific. The renderer must NOT make layout decisions — every
position and style comes from the Output tree.

## Approach

File: `lib/arrolio/renderer/pdf.rb`.

```ruby
class Arrolio::Renderer::Pdf
  def render(pages, io:)
    pdfrb_doc = Pdfrb::Document.new
    pages.each { |page| render_page(pdfrb_doc, page) }
    pdfrb_doc.write(io: io)
  end

  private

  def render_page(doc, output_page)
    pdfrb_page = doc.pages.add(media_box: [0, 0, *output_page.size])
    canvas = pdfrb_page.canvas
    output_page.regions.each_value do |region|
      render_region(canvas, region)
    end
    output_page.static_content.each { |sc| render_static(canvas, sc) }
  end

  def render_region(canvas, region)
    region.placed_boxes.each { |box| render_box(canvas, box) }
  end

  def render_box(canvas, box)
    case box.kind
    when :text  then render_text(canvas, box)
    when :image then render_image(canvas, box)
    when :shape then render_shape(canvas, box)
    end
  end
end
```

Mapping table from Arrolio Output concepts to Pdfrb primitives:

| Arrolio | Pdfrb |
|---|---|
| `Output::Page` of size `[w,h]` | `doc.pages.add(media_box: [0,0,w,h])` |
| `PlacedBox` kind `:text` | `canvas.text(content, at:, font:, size:, char_spacing:, word_spacing:)` |
| `PlacedBox` kind `:image` | `name = doc.images.add(path); canvas.image(name, at:, width:, height:)` |
| `PlacedBox` kind `:shape` (rectangle, line) | `canvas.rectangle/line + canvas.fill/stroke` |
| `StaticContent` | render via the same path, but at region-specific coordinates |

The renderer holds no state between pages — each page renders from
the Output tree afresh.

## Done-When

- [ ] `Renderer::Pdf.new.render([Output::Page.new(...)], io: StringIO.new)`
      produces bytes starting with `%PDF-`.
- [ ] A single text page renders the text correctly.
- [ ] Multi-page documents produce N pages with correct page numbers
      in PDF metadata.
- [ ] Round-trip: rendered PDF re-read by Pdfrb has the expected
      number of pages and extractable text.
- [ ] No layout decisions leak into the renderer (all coordinates
      come from Output::PlacedBox).
