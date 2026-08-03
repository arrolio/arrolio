---
priority: P0
phase: 17
depends_on: [52, 53]
layer: harness
est: 2d
status: pending
---

## Problem

End-to-end pipeline that ties together:
1. metanorma-document parses OIML presentation XML.
2. `Oiml::ContentAdapter` converts to `Arrolio::Content::Document`.
3. `Oiml::LayoutSpec.build` (TODO 53) supplies the OIML house style.
4. `Engine::Paged` lays out.
5. `Renderer::Pdf` produces bytes.

The PDF **diff** against FOP's reference is a separate concern —
covered by the comparator subsystem (TODOs 55–59). This TODO only
ships the pipeline and a minimal sanity-check spec.

## Approach

### Pipeline entry point

File: `lib/arrolio/oiml/pipeline.rb`.

```ruby
module Arrolio::Oiml
  module Pipeline
    module_function

    def call(presentation_xml_or_path, io:, **opts)
      require "metanorma/oiml/document"   # lazy-load heavy dep

      oiml_root = Metanorma::Oiml::Document::Root.parse(
        presentation_xml_or_path
      )
      content = ContentAdapter.new.convert(oiml_root)
      layout  = LayoutSpec.build
      flowables = FlowBuilder.(content, layout)
      pages = Arrolio::Engine::Paged.new(
        layout_spec: layout,
        flowables: flowables
      ).layout
      Arrolio::Renderer::Pdf.new.render(pages, io: io)
    end
  end
end
```

### CLI

File: `exe/arrolio-oiml` (executable).

```sh
arrolio-oiml render document.presentation.xml > document.pdf
arrolio-oiml diff   document.presentation.xml \
                    --reference=document.fop.pdf
```

The `diff` subcommand shells out to the comparator subsystem
(TODO 55) — this TODO only delivers `render`.

### Minimal sanity spec

`spec/arrolio/oiml/pipeline_spec.rb`:

```ruby
RSpec.describe "OIML → PDF pipeline", :e2e do
  Dir.glob("spec/fixtures/oiml/*.presentation.xml").each do |xml|
    it "#{File.basename(xml)} renders a valid PDF" do
      out = StringIO.new
      Arrolio::Oiml::Pipeline.(xml, io: out)
      expect(out.string).to start_with("%PDF-")
      expect(out.string).to include("%%EOF")

      reopened = Pdfrb::Document.new(io: StringIO.new(out.string))
      expect(reopened.pages.count).to be > 0
    end
  end
end
```

This is intentionally weak — no comparison vs FOP. The diff
subsystem (TODO 55–59) layers comparison on top.

## Done-When

- [ ] `Arrolio::Oiml::Pipeline.(xml, io:)` produces PDF bytes from
      every fixture.
- [ ] `exe/arrolio-oiml render doc.presentation.xml > out.pdf`
      produces a readable PDF.
- [ ] Pipeline spec runs against all fixtures without raising.
- [ ] Pipeline accepts either a path or a raw XML string.
- [ ] No FOP/diff code lives in this TODO — that's TODOs 55–59.
