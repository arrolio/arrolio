# frozen_string_literal: true

module Arrolio
  module Table
    # Computes column widths for a Content::Table based on natural
    # content widths. Each column gets at least its natural width
    # (longest unbreakable token + padding). Remaining space is
    # distributed proportionally to the column's natural width, so
    # wider columns get more extra space.
    #
    # If the total natural width exceeds the available width, columns
    # are scaled down proportionally (each gets a share proportional
    # to its natural width, but never below a minimum).
    class AutoLayout
      MIN_COLUMN_WIDTH = 20.0 # points — prevents columns from collapsing
      CELL_PADDING = 8.0      # points — left + right padding per cell

      attr_reader :table, :available_width, :measurer

      def initialize(table, available_width:, measurer: nil)
        @table = table
        @available_width = available_width.to_f
        @measurer = measurer || default_measurer
      end

      # Returns an Array of Float widths (one per column), summing
      # to +available_width+.
      def compute
        return Array.new(column_count, @available_width / column_count) if column_count.zero?

        natural = natural_widths
        distribute(natural)
      end

      private

      def column_count
        @table.column_count
      end

      # Natural width of each column = max cell natural width across
      # rows. Cells with colspan distribute their natural width
      # equally across the spanned slots so a wide header doesn't
      # accidentally collapse.
      def natural_widths
        widths = Array.new(column_count, MIN_COLUMN_WIDTH)
        @table.rows.each do |row|
          ci = 0
          row.cells.each do |cell|
            span = [cell.colspan.to_i, 1].max
            span = [span, column_count - ci].min
            w = cell_natural_width(cell)
            share = w / span.to_f
            span.times do |offset|
              idx = ci + offset
              break if idx >= widths.length

              widths[idx] = [widths[idx], share].max
            end
            ci += span
          end
        end
        widths
      end

      def cell_natural_width(cell)
        longest = cell.text.split(/\s+/).max_by(&:length) || ''
        @measurer.width_of_string(longest, font_size: 10.0) + CELL_PADDING
      end

      # Distribute +available_width+ across columns based on their
      # natural widths. If naturals fit, distribute extra space
      # proportionally. If they overflow, scale down proportionally
      # (but never below MIN_COLUMN_WIDTH).
      def distribute(natural)
        total_natural = natural.sum
        if total_natural >= @available_width
          scale_down(natural, total_natural)
        else
          distribute_extra(natural, total_natural)
        end
      end

      def scale_down(natural, total_natural)
        ratio = @available_width / total_natural
        natural.map { |w| [w * ratio, MIN_COLUMN_WIDTH].max }
      end

      def distribute_extra(natural, total_natural)
        extra = @available_width - total_natural
        natural.map.with_index do |w, _i|
          share = total_natural.positive? ? (w / total_natural) : 0.0
          w + (extra * share)
        end
      end

      def default_measurer
        GlyphMeasurer.new(font_name: 'Times-Roman')
      end
    end
  end
end
