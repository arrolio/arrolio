# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Tables
      def caption_runs_for(table)
        return nil if table.caption.nil?

        paragraph_flowable(table.caption, standalone: false).runs
      end

      # Table geometry (minimum row height, cell padding, footnote
      # size) is flavor configuration — extracted from the flavor's
      # XSL row/cell styles — not engine policy.
      def table_geometry
        config = @rules['table'] || {}
        {
          min_row_height: config.fetch('min_row_height', 0.0).to_f,
          cell_padding: config.fetch('cell_padding', 2.0).to_f,
          footnote_font_size: config['footnote_font_size']&.to_f
        }
      end
    end
  end
end
