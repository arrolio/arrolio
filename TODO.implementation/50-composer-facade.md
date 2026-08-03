---
priority: P2
phase: 16
depends_on: [02, 03, 20, 22]
layer: composer
est: 3d
status: in_progress
---

## Problem

Building Content + LayoutSpec by hand for every document is verbose.
The Composer facade provides a streaming "write a report" API:
`composer.heading("Intro"); composer.paragraph("...")`. It builds
Content + uses a default LayoutSpec under the hood.

## Approach

File: `lib/arrolio/composer.rb`.

```ruby
class Arrolio::Composer
  def initialize(page_size: :A4, margins: 25.mm, preset: :technical_report)
    @document = Arrolio::Content::Document.new
    @layout_spec = Arrolio::Presets.load(preset, page_size:, margins:)
    @current_section = @document
  end

  def heading(text, level: 1); ... end
  def paragraph(text, **style); ... end
  def table(headers:, rows:); ... end
  def list(items, marker: :bullet); ... end
  def image(path, **opts); ... end
  def page_break; ... end

  def write(path_or_io)
    pages = Arrolio::Engine::Paged.new(layout_spec: @layout_spec,
                                         flowables: build_flowables).layout
    Arrolio::Renderer::Pdf.new.render(pages, io: path_or_io)
  end

  private
  def build_flowables
    # Walk @document, produce Flowable[] per content node.
  end
end
```

Top-level convenience: `Arrolio.compose("out.pdf") { |c| ... }`.

## Done-When

- [ ] `Arrolio.compose("out.pdf") { |c| c.heading "Hi"; c.paragraph "World" }`
      produces a valid PDF.
- [ ] Heading uses the preset's heading style.
- [ ] Multiple paragraphs flow across pages.
- [ ] Tables and lists integrate.
- [ ] Image integration.
- [ ] Specs cover the public API surface.
