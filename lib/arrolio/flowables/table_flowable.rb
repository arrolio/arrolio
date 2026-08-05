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

        header_rows.each do |row|
          rh = row_height(row, cols, header: true)
          cursor -= rh
          consumed += rh
          cell_x = x.to_f
          row.cells.each_with_index do |cell, ci|
            cw = cols[ci] || (width / [row.cells.length, 1].max)
            render_cell(cell, cell_x, cursor, cw, rh, boxes, context, header: true)
            cell_x += cw
          end
        end
        body_rows.each do |row|
          rh = row_height(row, cols, header: false)
          cursor -= rh
          consumed += rh
          cell_x = x.to_f
          row.cells.each_with_index do |cell, ci|
            cw = cols[ci] || (width / [row.cells.length, 1].max)
            render_cell(cell, cell_x, cursor, cw, rh, boxes, context, header: false)
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

      def row_height(row, cols, header: false)
        max_h = 0.0
        row.cells.each_with_index do |cell, ci|
          cw = cols[ci] || 50.0
          content_h = cell.content.sum do |node|
            paragraph_height(node, cw, cell, header: header)
          end
          max_h = [max_h, content_h].max
        end
        max_h + 4.0
      end

      def paragraph_height(paragraph, width, _cell = nil, header: false)
        return 0.0 unless paragraph.is_a?(Content::Paragraph)

        style = cell_style(header: header)
        runs = paragraph.inline_runs.map { |r| InlineRun.new(r.text, style: style) }
        TextFlowable.new(runs, style: style).height(width)
      end

      def render_cell(cell, x, y, w, h, boxes, _context, header: false)
        style = cell_style(header: header)
        runs = []
        cell.content.each do |node|
          if node.is_a?(Content::Paragraph)
            runs.concat(node.inline_runs.map { |r| InlineRun.new(r.text, style: style) })
          end
        end
        if runs.any?
          tf = TextFlowable.new(runs, style: style.with(align: cell.align || style.align))
          tboxes, = tf.emit(x + 2, y + h - 2, w - 4, nil)
          boxes.concat(tboxes)
        end
        stroke = header ? 0.7 : 0.5
        boxes << Output::PlacedBox.rect(x: x, y: y, width: w, height: h,
                                        stroke_width: stroke, stroke_color: 'black')
      end

      def rebuild_table(header, body)
        Content::Table.new(header: header, body: body,
                           column_widths: @table.column_widths,
                           style_id: @table.style_id, id: @table.id)
      end

      # Resolve a cell's effective style. Header cells get the bold
      # variant of the table style. Body cells fall back to the
      # table style unless the cell declares its own style_id.
      def cell_style(header: false)
        base = @style.font_name ? @style : Style::Definition.new(font_name: 'Times-Roman', font_size: 10)
        return base unless header

        bold_name = bold_variant_of(base.font_name)
        base.with(font_name: bold_name)
      end

      def bold_variant_of(font_name)
        return font_name unless font_name

        case font_name.to_s
        when /\A(.*?)\z/ then "#{font_name} Bold"
        else font_name
        end
      end
    end
  end
end
