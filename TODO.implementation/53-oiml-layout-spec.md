---
priority: P0
phase: 17
depends_on: [52]
layer: harness
est: 5d
status: pending
---

## Problem

The OIML stylesheet (`oiml.xsl`) encodes OIML's house style:
specific page geometry, section-numbering format, running headers
with chapter title + doc number, table styling, TOC layout, etc.
We need to encode the *intent* of `oiml.xsl` as a Ruby
`Arrolio::LayoutSpec` — not by translating the XSL element-for-
element, but by reading what it produces visually and reproducing
that in Ruby.

## Approach

Read these sources of truth (in order):

1. **`~/src/mn/metanorma-taste/data/oiml/oiml.xsl`** — the XSL itself.
2. **Sample FOP-rendered OIML PDFs** — `~/src/mn/mn-samples-oiml/_site/documents/*/*.pdf`.
   Open in a viewer; measure geometry with a PDF inspector.
3. **The OIML document model** — `~/src/mn/metanorma-oiml/lib/metanorma/oiml/document/`
   to know what elements exist.

File: `lib/arrolio/oiml/layout_spec.rb` (Ruby-encoded OIML house style).

```ruby
module Arrolio::Oiml
  module LayoutSpec
    OIML_A4 = [595.28, 841.89].freeze  # A4 in pt

    def self.build
      Arrolio::LayoutSpec.build do
        # Page templates: cover, body (with running header + footer)
        page_template(:cover) do
          page_size OIML_A4
          margins top: 50, bottom: 50, left: 30, right: 30
        end

        page_template(:body) do
          page_size OIML_A4
          margins top: 35, bottom: 30, left: 25, right: 25
          region_extents before: 15, after: 15
        end

        # Page sequences: cover (single page) + body (odd/even differ)
        page_sequence(:front_matter, first: :cover, next: :cover)
        page_sequence(:main,
                      first: :body, odd: :body, even: :body,
                      page_numbering: { format: :arabic, start: 1 })

        # Styles (excerpt)
        style(:title,           font: "Helvetica-Bold", size: 24)
        style(:subtitle,        font: "Helvetica",      size: 14)
        style(:heading_1,       font: "Helvetica-Bold", size: 14,
                                space_before: 18, keep_with_next: true)
        style(:heading_2,       font: "Helvetica-Bold", size: 12)
        style(:body,            font: "Times-Roman",    size: 11,
                                align: :justify, line_spacing: 1.2)
        style(:table_header,    font: "Helvetica-Bold", size: 10,
                                background_color: "#EEEEEE")
        style(:table_cell,      font: "Times-Roman",    size: 10)
        style(:running_header,  font: "Helvetica",      size: 9)
        style(:footer,          font: "Helvetica",      size: 9, align: :center)

        # Static content bindings (running header + footer)
        static_content(:body, :before) do
          [
            # Left frame: current top-level section title
            Arrolio::PlacedText.new(
              content: ->(ctx) { ctx.current_section.numbered_title },
              style: :running_header,
              position: [0, 0, 80.mm, 15]
            ),
            # Right frame: doc reference
            Arrolio::PlacedText.new(
              content: ->(ctx) { ctx.metadata[:doc_reference] },
              style: :running_header,
              position: [100.mm, 0, 30.mm, 15]
            )
          ]
        end

        static_content(:body, :after) do
          [
            Arrolio::PlacedField.new(
              field: :page_number,
              style: :footer,
              position: [90.mm, 0, 10.mm, 15]
            )
          ]
        end
      end
    end
  end
end
```

This file is the **single source of truth** for OIML styling. To
change a colour, edit this file. To change page geometry, edit this
file. The XSL becomes irrelevant.

## Done-When

- [ ] `LayoutSpec.build` produces a valid Arrolio::LayoutSpec.
- [ ] Page geometry matches the OIML sample PDFs (measured to 1pt).
- [ ] Section numbering format matches OIML convention (`1`, `1.1`,
      `1.1.1`).
- [ ] Running header on a body page shows the current section title +
      doc reference.
- [ ] Footer shows page number centered.
- [ ] Tables in the OIML sample render with the right header styling.
- [ ] Cover page matches the OIML sample layout (title block, doc
      reference, etc.).
- [ ] Style is documented: every property choice cites the OIML
      sample PDF or the XSL line it was derived from.
