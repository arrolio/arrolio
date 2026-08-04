# frozen_string_literal: true

module Arrolio
  module Flowables
    # Real table layout: equal-width columns by default (TODO 04
    # adds auto/fixed), borders per cell, header row repeat.
    class TableFlowable < Flowable
      attr_reader :table, :column_widths

      def initialize(table, style: Style::Definition.new)
        super(style: style)
        @table = table
      end

      def height(width, _context = nil)
        cols = column_widths_for(width)
        total = 0.0
        rows.each do |row|
          total += row_height(row, cols)
        end
        total
      end

      def emit(x, y, width, context = nil)
        cols = column_widths_for(width)
        boxes = []
        consumed = 0.0
        cursor = y
        header_rows, body_rows = partition_rows

        (header_rows + body_rows).each do |row|
          rh = row_height(row, cols)
          cursor -= rh
          consumed += rh
          cell_x = x.to_f
          row.cells.each_with_index do |cell, ci|
            cw = cols[ci] || (width / [row.cells.length, 1].max)
            render_cell(cell, cell_x, cursor, cw, rh, boxes, context)
            cell_x += cw
          end
        end

        [boxes, consumed]
      end

      def splittable?
        true
      end

      def do_split(width, remaining_height, _context = nil)
        cols = column_widths_for(width)
        head_rows = []
        tail_rows = []
        used = 0.0
        header, body = partition_rows

        body.each do |row|
          rh = row_height(row, cols)
          if used + rh <= remaining_height || head_rows.empty?
            head_rows << row
            used += rh
          else
            tail_rows << row
          end
        end

        if head_rows.any?
          head_table = rebuild_table(header, head_rows)
          head = self.class.new(head_table, style: @style)
        else
          head = nil
        end

        tail_table = rebuild_table(header, tail_rows)
        tail = self.class.new(tail_table, style: @style)
        [head, tail]
      end

      private

      def rows
        @table.rows
      end

      def partition_rows
        [@table.header, @table.body]
      end

      def column_widths_for(width)
        return Array.new(@table.column_count, width.to_f / [@table.column_count, 1].max) if @table.column_count.zero?

        @cached_widths ||= Table::AutoLayout.new(@table, available_width: width).compute
      end

      def row_height(row, cols)
        max_h = 0.0
        row.cells.each_with_index do |cell, ci|
          cw = cols[ci] || 50.0
          content_h = cell.content.sum do |node|
            paragraph_height(node, cw)
          end
          max_h = [max_h, content_h].max
        end
        max_h + 4.0
      end

      def paragraph_height(paragraph, width)
        return 0.0 unless paragraph.is_a?(Content::Paragraph)

        style = cell_style(paragraph)
        runs = paragraph.inline_runs.map { |r| InlineRun.new(r.text, style: style) }
        TextFlowable.new(runs, style: style).height(width)
      end

      def render_cell(cell, x, y, w, h, boxes, _context)
        style = cell_style(cell)
        runs = []
        cell.content.each do |node|
          if node.is_a?(Content::Paragraph)
            runs.concat(node.inline_runs.map { |r| InlineRun.new(r.text, style: style) })
          end
        end
        if runs.any?
          tf = TextFlowable.new(runs, style: style)
          tboxes, = tf.emit(x + 2, y + h - 2, w - 4, nil)
          boxes.concat(tboxes)
        end
        # Cell border: rectangle around the full cell.
        boxes << Output::PlacedBox.rect(x: x, y: y, width: w, height: h,
                                        stroke_width: 0.5, stroke_color: 'black')
      end

      def rebuild_table(header, body)
        Content::Table.new(header: header.map { |r| r.cells.map(&:text) },
                           body: body.map { |r| r.cells.map(&:text) })
      end

      # Use the parent table's style (which inherits from body) rather
      # than hard-coding a font. Falls back to Times-Roman only if the
      # table style has no font_name (shouldn't happen in practice).
      def cell_style(_cell_or_para)
        @style.font_name ? @style : Style::Definition.new(font_name: 'Times-Roman', font_size: 10)
      end
    end
  end
end
