# frozen_string_literal: true

module Arrolio
  # A multi-column frame that splits a region's width into N equal
  # columns. The engine flows content column-by-column: when one
  # column overflows, content moves to the next column; when all
  # columns overflow, the page breaks. This is the foundation for
  # multi-column body text (e.g., 2-column technical specs).
  #
  # Usage in layout spec YAML:
  #   page_templates:
  #     body:
  #       columns: 2
  #       column_gap: 6mm
  class ColumnSet
    attr_reader :column_count, :gap, :total_width, :total_height

    def initialize(column_count:, gap:, total_width:, total_height:)
      @column_count = column_count.to_i
      @gap = gap.to_f
      @total_width = total_width.to_f
      @total_height = total_height.to_f
      freeze
    end

    # Width of a single column (total - gaps) / count.
    def column_width
      return @total_width if @column_count <= 1

      (@total_width - (@gap * (@column_count - 1))) / @column_count
    end

    # X position of column at +index+ (0-based).
    def column_x(index)
      return 0.0 if @column_count <= 1

      index * (column_width + @gap)
    end

    # Enumerate each column as a [x, width] pair.
    def each_column
      return enum_for(:each_column) unless block_given?

      @column_count.times { |i| yield(column_x(i), column_width) }
    end

    def single_column?
      @column_count <= 1
    end

    def ==(other)
      other.is_a?(self.class) &&
        column_count == other.column_count &&
        gap == other.gap &&
        total_width == other.total_width &&
        total_height == other.total_height
    end
    alias eql? ==

    def hash
      [self.class, column_count, gap, total_width, total_height].hash
    end
  end
end
