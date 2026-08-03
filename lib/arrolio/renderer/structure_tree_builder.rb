# frozen_string_literal: true

module Arrolio
  module Renderer
    # Builds a PDF structure tree (/StructTreeRoot) for PDF/UA
    # compliance. Walks the Output::Page[] tree and creates
    # /StructElem entries for each content block (paragraphs,
    # headings, tables, figures). The structure tree maps marked
    # content sequences to semantic roles so assistive technology
    # can navigate the document.
    #
    # The builder is a foundation — full PDF/UA compliance also
    # requires /Alt text (AccessibilityTagger), reading order,
    # and /ActualText for non-text content. This builder creates
    # the tree skeleton; the renderer fills in marked content refs.
    class StructureTreeBuilder
      # Standard PDF structure types from PDF 1.7 Table 10.20.
      STRUCT_TYPES = {
        document: :Document,
        part: :Part,
        section: :Sect,
        heading: :H,
        heading1: :H1,
        heading2: :H2,
        heading3: :H3,
        paragraph: :P,
        table: :Table,
        table_row: :TR,
        table_header: :TH,
        table_data: :TD,
        list: :L,
        list_item: :LI,
        figure: :Figure,
        caption: :Caption,
        footnote: :Footnote,
        link: :Link,
        quote: :BlockQuote,
        code: :Code
      }.freeze

      attr_reader :document, :entries

      def initialize(document)
        @document = document
        @entries = []
        @next_mcid = 0
      end

      # Records a structure element for a content block.
      # +type:+ one of STRUCT_TYPES keys.
      # +page_number:+ the page where the content appears.
      # +text:+ optional text content for the /Alt entry.
      # +alt:+ optional alt text for non-text content.
      def record(type:, page_number:, text: nil, alt: nil)
        entry = StructEntry.new(
          type: struct_type_for(type),
          page_number: page_number,
          mcid: @next_mcid,
          text: text,
          alt: alt
        )
        @entries << entry
        @next_mcid += 1
        entry
      end

      # Builds and attaches the /StructTreeRoot to the document
      # catalog. Returns the root reference or nil if no entries.
      def build
        return nil if @entries.empty?

        struct_elements = @entries.map { |e| build_struct_elem(e) }
        root = @document.add(
          { Type: :StructTreeRoot,
            K: struct_elements.map { |ref| ref_for(ref) } },
          type: Pdfrb::Model::Cos::Dictionary
        )
        @document.catalog.value[:StructTreeRoot] =
          Pdfrb::Model::Reference.new(root.oid, root.gen)
        root
      end

      def count
        @entries.length
      end

      def empty?
        @entries.empty?
      end

      # Internal structure entry record.
      StructEntry = Struct.new(:type, :page_number, :mcid, :text, :alt,
                               keyword_init: true)

      private

      def struct_type_for(type)
        STRUCT_TYPES.fetch(type, :P)
      end

      def build_struct_elem(entry)
        dict = {
          Type: :StructElem,
          S: entry.type,
          Pg: nil,
          MCID: entry.mcid
        }
        dict[:Alt] = entry.alt if entry.alt && !entry.alt.empty?
        @document.add(dict, type: Pdfrb::Model::Cos::Dictionary)
      end

      def ref_for(obj)
        Pdfrb::Model::Reference.new(obj.oid, obj.gen)
      end
    end
  end
end
