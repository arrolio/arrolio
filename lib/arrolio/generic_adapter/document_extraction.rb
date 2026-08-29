# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Extracted conversion seam (TODO 56): one module per concern,
    # included into the adapter. The class keeps dispatch and glue.
    module DocumentExtraction
      def extract_sections(root)
        sections_config = @rules['sections'] || {}
        container = sections_config['container'] || 'sections'
        sections_elem = find_first(root, container)
        return [] unless sections_elem

        children = []
        each_direct_child(sections_elem) do |child|
          next unless map_element(child.name, sections_elem) == 'section'

          children << convert_clause(child)
        end
        children
      end

      def extract_title_block(root)
        sections_config = @rules['sections'] || {}
        container = sections_config['container'] || 'sections'
        sections_elem = find_first(root, container)
        return nil unless sections_elem

        para_name = selector('paragraph')
        each_direct_child(sections_elem) do |child|
          next unless child.name == para_name

          cls = child.attribute('class')&.value
          title_style = (@rules['paragraph_styles'] || {})[cls]
          next unless title_style

          return Content::Paragraph.new(
            title_block_runs(root),
            style_id: title_style.to_sym,
            id: child.attribute(selector('id_attribute'))&.value
          )
        end
        nil
      end

      def title_block_runs(root)
        metadata = extract_metadata(root)
        part = metadata[:part_number].to_s
        title_part = metadata[:title_part].to_s
        locality = @rules.dig('i18n', 'locality_part').to_s
        locality = 'Part' if locality.empty?
        text = if part.empty? && title_part.empty?
                 ''
               elsif part.empty?
                 title_part
               else
                 "#{locality} #{part} - #{title_part}".strip
               end
        [Content::InlineRun.new(text, style_id: :doc_title)]
      end

      def extract_preface(root)
        preface_elem = find_first(root, selector('preface_container'))
        return [] unless preface_elem

        result = []
        each_element(preface_elem) do |child|
          next if child == preface_elem
          next unless Array(selector('preface_children')).include?(child.name)

          result << convert_clause(child, context: :preface)
        end
        result
      end

      def extract_bibliography(root)
        biblio_elem = find_first(root, selector('bibliography_container'))
        return [] unless biblio_elem

        result = []
        each_element(biblio_elem) do |child|
          next if child == biblio_elem
          next unless child.name == selector('bibliography_reference')

          items = []
          each_child(child, selector('bibliography_item')) do |bi|
            items.concat(convert_bibitem(bi))
          end
          result << Content::Section.new(
            title: 'Bibliography',
            level: 1,
            children: items,
            style_id: :section_body_1,
            title_style_id: title_style_for('bibliography', 1)
          )
        end
        result
      end
    end
  end
end
