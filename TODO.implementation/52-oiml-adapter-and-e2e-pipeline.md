---
priority: P0
phase: 17
depends_on: [23, 30, 32, 33, 39, 42]
layer: harness
est: 3d
status: pending
---

## Problem

**This is Arrolio's primary end-to-end correctness test.** The user's
requirement: define OIML PDF output (from the existing `oiml.xsl`),
use the `metanorma-document` gem to parse real OIML presentation XML,
convert that into Arrolio's content model, apply an OIML LayoutSpec,
and render via Pdfrb. If Arrolio can produce FOP-equivalent PDFs for
real OIML documents, the engine is correct.

This TODO sets up the **adapter gem** (or namespace) that bridges
metanorma-document → Arrolio. Phase-17 TODOs 53–55 build the OIML
LayoutSpec and the diff harness around this.

## Approach

The bridge has three parts:

### 1. OIML fixture corpus

Live in `spec/fixtures/oiml/` (gitignored if licensing requires):
- 3–5 real OIML presentation XML files at varying complexity
  (cover + TOC + 5 sections + tables; multi-section with figures;
  full 50-page reference doc).
- For each, a FOP-rendered reference PDF (the ground truth).

A rake task `rake fixtures:refresh_oiml` regenerates the reference
PDFs by running `xsltproc oiml.xsl + fop` if the user has FOP
installed; otherwise fetches pre-rendered ones from a private repo.

### 2. `Arrolio::Oiml` adapter (in this gem, spec-only initially)

Files under `lib/arrolio/oiml/`:

- `content_adapter.rb` — converts
  `Metanorma::Oiml::Document::Root` → `Arrolio::Content::Document`.
  Walks the typed model, dispatches per node class via
  `BlockDispatcher` (mirrors the STS transformer pattern):

  ```ruby
  class ContentAdapter
    def convert(oiml_root) -> Arrolio::Content::Document
    def convert_clause(clause) -> Arrolio::Content::Section
    def convert_paragraph(p) -> Arrolio::Content::Paragraph
    def convert_table(t) -> Arrolio::Content::Table
    def convert_list(l) -> Arrolio::Content::List
    def convert_image(i) -> Arrolio::Content::Image
    # etc.
  end
  ```

  Inline content (text + spans + cross-references) maps to
  `Arrolio::InlineRun[]`.

- `layout_spec_loader.rb` — loads the OIML LayoutSpec (TODO 53).

- `pipeline.rb` — orchestrates:
  ```ruby
  oiml_root = Metanorma::Oiml::Document::Root.parse(xml)
  content   = ContentAdapter.new.convert(oiml_root)
  layout    = LayoutSpecLoader.load("oiml.layout_spec.rb")
  flowables = FlowBuilder.(content, layout)
  pages     = Arrolio::Engine::Paged.new(layout_spec: layout,
                                           flowables:).layout
  Arrolio::Renderer::Pdf.new.render(pages, io:)
  ```

### 3. End-to-end spec

`spec/arrolio/oiml_e2e_spec.rb` (tagged `:e2e`):

```ruby
RSpec.describe "OIML → PDF end-to-end", :e2e do
  Dir.glob("spec/fixtures/oiml/*.presentation.xml").each do |xml_path|
    it "renders #{File.basename(xml_path)} to a valid PDF" do
      out = StringIO.new
      Arrolio::Oiml::Pipeline.(File.read(xml_path), io: out)

      # Sanity: valid PDF
      expect(out.string).to start_with("%PDF-")
      expect(out.string).to include("%%EOF")

      # Re-readable
      reopened = Pdfrb::Document.new(io: StringIO.new(out.string))
      expect(reopened.pages.count).to be > 0

      # Diff vs FOP reference (TODO 55)
      ref_path = xml_path.sub(".presentation.xml", ".fop.pdf")
      if File.exist?(ref_path)
        diff = Arrolio::Harness::TextDiff.(
          ours: out.string,
          reference: File.binread(ref_path)
        )
        expect(diff.page_count_delta).to be <= 1   # tolerate off-by-one
        expect(diff.text_similarity).to be > 0.95
      end
    end
  end
end
```

## Done-When

- [ ] `Metanorma::Oiml::Document::Root` (or its base class) loads
      fixture XMLs without error.
- [ ] `ContentAdapter` converts every fixture without raising.
- [ ] `Pipeline` produces bytes starting with `%PDF-` for every fixture.
- [ ] Each rendered PDF re-reads via Pdfrb with the expected page count.
- [ ] Adapter covers at minimum: clause, paragraph, table, list,
      image, heading (sections 1, 1.1, 1.1.1), footnote, basic-link.
- [ ] Each adapter method is unit-tested with a minimal input.
- [ ] `rake oiml:render[xml_path]` CLI command renders a single doc.
