# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Extracted conversion seam (TODO 56): one module per concern,
    # included into the adapter. The class keeps dispatch and glue.
    module HeadingExtraction
      # The level derives from the autonumber's dotted depth ("5.1.1"
      # → 3, "A.1" → 2) when present — the semantic truth — falling
      # back to the fmt-title depth attribute. Titles without either
      # stay level 1. Relying on the attribute alone mis-leveled most
      # sections (3.x, 5.1.x) because their fmt-title carries no depth.
      def clause_level(elem, number: nil)
        dotted = number.to_s.split('.').length
        return dotted if dotted > 1 && number.to_s.match?(/\A[\dA-Z]/)

        heading_name = selector('heading')
        depth_attr = selector('heading_depth_attribute')
        fmt_title = elem.elements.first { |e| e.name == heading_name }
        depth = fmt_title&.attribute(depth_attr)&.value.to_i
        [depth, 1].max
      end

      def extract_heading(clause)
        heading_config = @rules['heading'] || {}
        source = heading_config['source'] || selector('heading')
        heading_elem = find_first(clause, source)
        if heading_elem
          extract_from_heading(heading_elem)
        else
          title = find_first(clause, selector('fallback_title'))
          [title ? text_of(title) : nil, nil]
        end
      end

      def extract_from_heading(heading_elem)
        parts = []
        number_parts = []
        title_parts = []
        non_number_parts = []
        autonum_class = selector('autonum_class')
        autonum_delim_class = selector('autonum_delim_class') || 'fmt-autonum-delim'
        caption_label_class = selector('caption_label_class') || 'fmt-caption-label'

        walk_heading_text(heading_elem) do |text, parent|
          parts << text
          element_attr = parent&.attribute('element')&.value
          parent_class = parent&.attribute('class')&.value
          if element_attr == 'autonum' ||
             parent_class == autonum_class ||
             parent_class == autonum_delim_class ||
             parent_class == caption_label_class
            number_parts << text
          elsif element_attr == 'title'
            title_parts << text
            non_number_parts << text
          else
            non_number_parts << text
          end
        end

        number = number_parts.map(&:strip).reject(&:empty?).join
        number = nil if number.empty?

        title = if title_parts.any?
                  title_parts.join.strip
                elsif parts.include?("\t")
                  parts.join.split("\t", 2).last&.strip
                else
                  non_number_parts.join.strip
                end
        title = nil if title.nil? || title.empty?
        [title, number]
      end

      def walk_heading_text(element, &block)
        element.children.each do |child|
          next if child.is_a?(REXML::Element) &&
                  (XREF_ELEMENTS.include?(child.name) ||
                   child.attribute('element')&.value == 'xref')

          case child
          when REXML::Text
            yield(child.value, child.parent)
          when REXML::Element
            walk_heading_text(child, &block)
          end
        end
      end
    end
  end
end
