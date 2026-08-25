# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Table conversion, split from the adapter body (TODO 56 MECE
    # split). Converts <table> to Content::Table: rows and cells
    # with colspan/rowspan/alignment, captions, and cell footnotes
    # lifted to the table.
    module TableConversion
      def convert_table(elem)
        header, header_footnotes = convert_table_rows(find_first(elem, selector('table_header')), true)
        body, body_footnotes = convert_table_rows(find_first(elem, selector('table_body')), false)
        caption = extract_table_caption(elem)
        Content::Table.new(header: header, body: body, style_id: :table,
                           id: elem.attribute(selector('id_attribute'))&.value,
                           caption: caption,
                           footnotes: header_footnotes + body_footnotes)
      end

      # The caption carries inline content (math subscripts, xrefs) —
      # flattening to text serializes stems to their raw asciimath
      # form ("n_(\"LC\")"). Collect runs like figure captions do.
      def extract_table_caption(elem)
        name = find_first(elem, selector('figure_caption')) ||
               find_first(elem, selector('figure_caption_fallback'))
        return nil unless name

        runs = collect_inline_runs(name)
        runs.empty? ? nil : Content::Paragraph.new(runs, style_id: :figure_caption)
      end

      def convert_table_rows(parent, is_header)
        return [[], []] unless parent

        rows = []
        footnotes = []
        row_name = selector('table_row')
        cell_names = Array(selector('table_cell'))
        each_child(parent, row_name) do |tr|
          cells = []
          each_element(tr) do |cell|
            next unless cell_names.include?(cell.name)

            runs, cell_footnotes = cell_runs_with_footnotes(cell)
            footnotes.concat(cell_footnotes)
            cells << Content::Table::Cell.new(
              [Content::Paragraph.new(runs, style_id: is_header ? :table_header_cell : :table_cell)],
              colspan: (cell.attribute('colspan')&.value || 1).to_i,
              rowspan: (cell.attribute('rowspan')&.value || 1).to_i,
              style_id: is_header ? :table_header_cell : :table_cell,
              align: cell.attribute('align')&.value,
              valign: cell.attribute('valign')&.value
            )
          end
          rows << Content::Table::Row.new(cells)
        end
        [rows, footnotes]
      end

      # Footnotes referenced from table cells keep only their marker
      # (a superscript run) in the cell; their body is collected onto
      # the table and rendered below it — the FOP table-footnote
      # convention. Inline collection skips the marker element's
      # subtree so the body text never leaks into the cell.
      def cell_runs_with_footnotes(cell)
        fn_name = selector('footnote_marker')
        runs = collect_inline_runs(cell, exclude: fn_name)
        return [runs, []] unless fn_name

        footnotes = []
        cell.each_recursive do |node|
          next unless node.is_a?(REXML::Element) && node.name == fn_name

          marker = node.attribute('reference')&.value ||
                   node.attribute('id')&.value || ''
          unless marker.empty?
            runs << Content::InlineRun.new(
              marker, style_id: :inline,
                      baseline_shift: Content::InlineRun::BASELINE_SUP,
                      font_size_scale: 0.7
            )
          end
          footnotes << table_footnote(node, marker)
        end
        [runs, footnotes]
      end

      def table_footnote(fn_elem, marker)
        para_name = selector('paragraph')
        body = []
        each_element(fn_elem) do |child|
          next unless child.name == para_name

          body << convert_paragraph(child)
        end
        Content::Footnote.new(
          marker: marker,
          body: body,
          id: fn_elem.attribute(selector('id_attribute'))&.value
        )
      end

    end
  end
end
