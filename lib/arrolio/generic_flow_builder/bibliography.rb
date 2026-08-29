# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Bibliography
      def bibliography_item_flowable(item, out)
        tag = item.tag.to_s
        body_para = bibliography_body_paragraph(item)
        if tag.empty?
          out << paragraph_flowable(body_para)
          return
        end

        body = paragraph_flowable(body_para)
        out << Flowables::NoteFlowable.new(
          tag,
          [body],
          style: resolve(item.style_id || :bibitem),
          label_style: resolve(:bibitem_marker),
          marker_width: 24.0
        )
      end

      def bibliography_body_paragraph(item)
        runs = []
        if item.formattedref
          runs.concat(item.formattedref.inline_runs.map do |r|
            Content::InlineRun.new(r.text, style_id: r.style_id)
          end)
        end
        Content::Paragraph.new(runs, style_id: item.style_id || :bibitem,
                                     id: item.id)
      end

      def marker_width_of(tag)
        return 0.0 if tag.to_s.empty?

        style = resolve(:bibitem_marker)
        GlyphMeasurer.new(font_name: style.font_name)
                     .width_of_string("#{tag} ", font_size: style.font_size)
      end
    end
  end
end
