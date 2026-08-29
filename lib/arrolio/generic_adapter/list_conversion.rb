# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Extracted conversion seam (TODO 56): one module per concern,
    # included into the adapter. The class keeps dispatch and glue.
    module ListConversion
      def convert_list(elem, kind:)
        return convert_definition_list(elem) if elem.name == 'dl'

        items = []
        item_name = selector('list_item')
        label_name = selector('list_item_label')
        para_name = selector('paragraph')
        list_mapping = (@rules['element_mapping'] || {}).select do |_, v|
          v['content_type'] == 'list'
        end
        each_child(elem, item_name) do |li|
          # Ordered lists carry their autonum in the label element;
          # unordered lists don't number (the label text is a
          # placeholder) — they render the flavor's bullet instead.
          marker = nil
          if kind != :bullet
            label_elem = find_first(li, label_name)
            marker = text_of(label_elem) if label_elem
          end

          content = []
          each_element(li) do |child|
            next if child.parent && child.parent != li

            if child.name == para_name
              content << convert_paragraph(child)
            elsif list_mapping.key?(child.name)
              nested_kind = list_mapping[child.name]['kind']&.to_sym || :bullet
              content << convert_list(child, kind: nested_kind)
            end
          end
          content = [Content::Paragraph.new(collect_inline_runs(li))] if content.empty?
          items << Content::List::Item.new(content, marker: marker)
        end
        Content::List.new(items, kind: kind, style_id: kind == :ordered ? :list_ordered : :list_bullet)
      end

      def convert_definition_list(elem)
        items = []
        para_name = selector('paragraph')
        current_marker = nil

        each_direct_child(elem) do |child|
          case child.name
          when 'dt'
            current_marker = text_of(child).strip
          when 'dd'
            content = []
            each_element(child) do |c|
              next unless c.name == para_name && c.parent == child
              content << convert_paragraph(c)
            end
            content = [Content::Paragraph.new(collect_inline_runs(child))] if content.empty?
            items << Content::List::Item.new(content, marker: current_marker)
            current_marker = nil
          end
        end

        Content::List.new(items, kind: :definition, style_id: :list_bullet)
      end
    end
  end
end
