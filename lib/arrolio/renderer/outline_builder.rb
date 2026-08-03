# frozen_string_literal: true

module Arrolio
  module Renderer
    # Builds the PDF /Outlines tree from FlowContext#heading_entries.
    # Each entry becomes an /Outlines item with /Title and /Dest
    # pointing at its source page's top. Called by Renderer::Pdf
    # AFTER all pages have been emitted (so page refs exist).
    class OutlineBuilder
      attr_reader :document, :entries, :pdfrb_pages

      def initialize(document:, entries:, pdfrb_pages:)
        @document = document
        @entries = entries
        @pdfrb_pages = pdfrb_pages
      end

      def build
        return nil if entries.empty?

        items = build_items
        return nil if items.empty?

        root = document.add(
          {
            Type: :Outlines,
            First: ref(items.first),
            Last: ref(items.last),
            Count: items.length
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
        catalog = document.catalog
        catalog.value[:Outlines] = ref(root)
        root
      end

      private

      def build_items
        items = []
        prev = nil
        entries.each do |entry|
          outline_entry = build_one(entry)
          next unless outline_entry

          if prev
            prev.value[:Next] = ref(outline_entry)
            outline_entry.value[:Prev] = ref(prev)
          end
          items << outline_entry
          prev = outline_entry
        end
        items
      end

      def build_one(entry)
        page_ref = page_ref_at(entry[:page_number])
        return nil unless page_ref

        title = [entry[:number], entry[:title]].compact.join(' ').to_s
        document.add(
          {
            Type: :Outlines,
            Title: title.encode('UTF-8', invalid: :replace, undef: :replace),
            Parent: parent_ref,
            Dest: [page_ref, :XYZ, 0, page_height(entry[:page_number]), nil]
          },
          type: Pdfrb::Model::Cos::Dictionary
        )
      end

      def page_ref_at(page_number)
        page = pdfrb_pages[page_number - 1]
        return nil unless page

        Pdfrb::Model::Reference.new(page.oid, page.gen)
      end

      def page_height(page_number)
        page = pdfrb_pages[page_number - 1]
        return 800.0 unless page

        box = page.value[:MediaBox]
        return 800.0 unless box

        box.is_a?(Array) ? box[3].to_f : 800.0
      end

      def parent_ref
        return @parent_ref if @parent_ref

        root = document.catalog.value[:Outlines]
        @parent_ref = root
      end

      def ref(obj)
        Pdfrb::Model::Reference.new(obj.oid, obj.gen)
      end
    end
  end
end
