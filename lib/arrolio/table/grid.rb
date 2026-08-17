# frozen_string_literal: true

module Arrolio
  module Table
    # Occupancy grid over a Content::Table, honoring colspan and
    # rowspan. Answers the two questions every table consumer asks:
    # which column does each cell actually occupy, and which rows are
    # welded together by a vertical span (and therefore cannot be
    # split apart across pages).
    #
    # Built once per layout pass and shared by AutoLayout (natural
    # widths), TableFlowable (row heights, cell placement), and
    # splitting (atomic row groups).
    class Grid
      # One cell's position in the grid. +row_index+ is the row the
      # cell STARTS in — a rowspan cell is placed and drawn only
      # there, with a height covering every spanned row.
      Placement = Struct.new(:cell, :row_index, :column_index,
                             :colspan, :rowspan, keyword_init: true) do
        def spans_multiple_rows?
          rowspan > 1
        end

        def spans_multiple_columns?
          colspan > 1
        end
      end

      attr_reader :placements, :row_count, :column_count

      def self.build(table)
        rows = table.rows
        occupied = {}
        placements = []
        rows.each_with_index do |row, row_index|
          column_index = 0
          row.cells.each do |cell|
            column_index += 1 while occupied[[row_index, column_index]]
            colspan = cell.colspan.to_i
            rowspan = cell.rowspan.to_i
            placements << Placement.new(
              cell: cell, row_index: row_index, column_index: column_index,
              colspan: colspan, rowspan: rowspan
            )
            rowspan.times do |r|
              colspan.times do |c|
                occupied[[row_index + r, column_index + c]] = true
              end
            end
            column_index += colspan
          end
        end
        new(placements: placements, row_count: rows.length,
            column_count: occupied.keys.map(&:last).max.to_i + 1)
      end

      def initialize(placements:, row_count:, column_count:)
        @placements = placements.freeze
        @row_count = row_count
        @column_count = column_count
        @by_row = Array.new(row_count) { [] }
        @placements.each { |p| @by_row[p.row_index] << p }
        @by_row.each(&:freeze)
        freeze
      end

      def placements_starting_in(row_index)
        @by_row[row_index] || []
      end

      # Rows welded together by rowspan cells, as arrays of row
      # indexes in ascending order. Rows not covered by any span come
      # back as single-element groups. Splitting the table across
      # pages must happen between groups, never inside one.
      def atomic_row_groups
        groups = []
        group = []
        welded = welded_rows
        (0...@row_count).each do |row_index|
          group << row_index
          next if welded.include?(row_index + 1)

          groups << group.freeze
          group = []
        end
        groups << group.freeze unless group.empty?
        groups.freeze
      end

      private

      # Row indexes > 0 whose content starts in the row above (i.e.
      # a rowspan from above covers their first column slot).
      def welded_rows
        covered = {}
        @placements.each do |p|
          next unless p.spans_multiple_rows?

          (1...p.rowspan).each { |r| covered[p.row_index + r] = true }
        end
        covered
      end
    end
  end
end
