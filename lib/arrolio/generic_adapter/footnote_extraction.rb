# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Footnote extraction, split from the adapter body (TODO 56
    # MECE split). Included as a module so the extraction logic
    # stays with its selectors while the adapter class stays lean.
    module FootnoteExtraction
      # Footnotes come in two shapes: the formatted container
      # (fmt-footnote-container + fmt-fn-body) and the raw marker
      # element (<fn reference="a">) whose body is its own paragraphs.
      # Both register in Document#footnotes, keyed by id; the raw form
      # is what body text and table cells reference.
      def extract_footnotes(root)
        container_name = selector('footnote_container')
        body_name = selector('footnote_body')
        marker_name = selector('footnote_marker')
        return [] unless marker_name || (container_name && body_name)

        footnotes = []
        ids = []
        # Recursive: footnote containers and raw <fn> markers live at
        # arbitrary depths inside clauses, tables, and terms.
        root.each_recursive do |elem|
          if container_name && elem.name == container_name

          marker = elem.attribute('id')&.value || elem.attribute(marker_name)&.value || ''
          body_elem = find_first(elem, body_name)
          body = []
          if body_elem
            para_name = selector('paragraph')
            each_element(body_elem) do |child|
              next unless child.name == para_name

              body << convert_paragraph(child)
            end
          end
          next if body.empty?

          id = elem.attribute(selector('id_attribute'))&.value
          next if id && ids.include?(id)

          ids << id if id
          footnotes << Content::Footnote.new(
            marker: marker,
            body: body,
            id: id
          )
          elsif marker_name && elem.name == marker_name
            id = elem.attribute('id')&.value ||
                 elem.attribute(selector('id_attribute'))&.value
            next if id && ids.include?(id)

            marker = elem.attribute('reference')&.value || id || ''
            body = footnote_body_paragraphs(elem)
            next if body.empty?

            ids << id if id
            footnotes << Content::Footnote.new(
              marker: marker,
              body: body,
              id: id
            )
          end
        end
        footnotes
      end

      def footnote_body_paragraphs(elem)
        para_name = selector('paragraph')
        paragraphs = []
        each_element(elem) do |child|
          next unless child.name == para_name

          paragraphs << convert_paragraph(child)
        end
        paragraphs
      end
    end
  end
end
