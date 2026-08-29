# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Lists
      def list_flowable(list, container: nil)
        items = list.items.each_with_index.map do |item, index|
          marker = item.marker.nil? ? default_marker(list, index, container: container) : item.marker
          body = item.content.flat_map do |content|
            flowable_for_list_content(content)
          end
          [marker, body]
        end
        Flowables::ListFlowable.new(items, kind: list.kind,
                                           style: resolve(list.style_id),
                                           **list_geometry(list.kind, container: container))
      end

      # List marker geometry (indent, marker column, inter-item
      # spacing) is flavor configuration extracted from the flavor's
      # XSL list styles — not engine policy.
      # A kind-specific map (e.g. geometry.ordered) overrides the
      # shared defaults — flavors whose bullets indent but whose
      # ordered markers start at the margin (which also restores
      # nested lists' depth).
      def list_geometry(kind, container: nil)
        config = @rules.dig('list', 'geometry') || {}
        config = config.merge(config[kind.to_s] || {})
        # Lists nested in note bodies sit deeper: the reference puts
        # 3.1.3.1's note bullets at +43.7pt from the note column
        # (marker x=143 from the page), pitch 17pt.
        config = config.merge(@rules.dig('note', 'list') || {}) if container == :note
        {
          marker_indent: config.fetch('marker_indent', 0.0).to_f,
          marker_width: config.fetch('marker_width', 18.0).to_f,
          body_indent: config.fetch('body_indent', 6.0).to_f,
          item_spacing: config.fetch('item_spacing', 0.0).to_f
        }
      end

      def flowable_for_list_content(content)
        case content
        when Content::Paragraph then [paragraph_flowable(content)]
        when Content::List then [list_flowable(content)]
        else []
        end
      end

      def default_marker(list, index, container: nil)
        defaults = @rules.dig('list', 'defaults') || {}
        if list.ordered?
          format = defaults['ordered_marker'] || '%d.'
          format.sub('%d', (index + 1).to_s)
        else
          nested = @rules.dig('note', 'list') || {}
          return nested['bullet_marker'] if container == :note && nested['bullet_marker']

          defaults['bullet_marker'] || '■ '
        end
      end
    end
  end
end
