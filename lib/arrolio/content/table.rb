# frozen_string_literal: true

module Arrolio
  module Content
    class Table
      attr_reader :header, :body, :column_widths, :style_id, :id

      def initialize(header: [], body: [], column_widths: nil,
                     style_id: :table, id: nil)
        @header = header.map { |row| coerce_row(row) }.freeze
        @body = body.map { |row| coerce_row(row) }.freeze
        @column_widths = column_widths&.map(&:to_f)&.freeze
        @style_id = style_id.to_sym
        @id = id
        freeze
      end

      def rows
        @header + @body
      end

      def column_count
        rows.map { |r| r.cells.length }.max || 0
      end

      def ==(other)
        other.is_a?(self.class) &&
          header == other.header &&
          body == other.body &&
          column_widths == other.column_widths &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, header, body, column_widths, style_id, id].hash
      end

      private

      def coerce_row(row)
        case row
        when Row then row
        when Array then Row.new(row.map { |c| c.is_a?(Cell) ? c : Cell.new(c) })
        else
          raise ContentError, "Table row must be an Array or Table::Row (got #{row.class})"
        end
      end
    end

    class Table::Row
      include Enumerable

      attr_reader :cells, :min_height

      def initialize(cells, min_height: 0.0)
        @cells = Array(cells).freeze
        @min_height = min_height.to_f.freeze
        freeze
      end

      def each(&block)
        @cells.each(&block)
      end

      def length
        @cells.length
      end

      def ==(other)
        other.is_a?(self.class) && cells == other.cells &&
          min_height == other.min_height
      end

      alias eql? ==

      def hash
        [self.class, cells, min_height].hash
      end
    end

    class Table::Cell
      attr_reader :content, :colspan, :rowspan, :style_id, :align

      def initialize(content = [], colspan: 1, rowspan: 1,
                     style_id: :table_cell, align: nil)
        @content = Array(content).freeze
        @colspan = colspan.to_i
        @rowspan = rowspan.to_i
        @style_id = style_id.to_sym
        @align = align
        freeze
      end

      def text
        @content.map do |node|
          node.is_a?(Paragraph) ? node.text : node.to_s
        end.join(' ')
      end

      def ==(other)
        other.is_a?(self.class) &&
          content == other.content &&
          colspan == other.colspan &&
          rowspan == other.rowspan &&
          style_id == other.style_id &&
          align == other.align
      end

      alias eql? ==

      def hash
        [self.class, content, colspan, rowspan, style_id, align].hash
      end
    end
  end
end
