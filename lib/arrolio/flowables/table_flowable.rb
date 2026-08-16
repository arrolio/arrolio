# frozen_string_literal: true

module Arrolio
  module Flowables
    # Real table layout: equal-width columns by default (TODO 04
    # adds auto/fixed), borders per cell, header row repeat,
    # continuation caption on split.
    class TableFlowable < Flowable
      attr_reader :table, :column_widths, :continued, :caption_text

      CAPTION_DASH = Regexp.new("[\u00A0\u2009\u0020]\u2014").freeze

      def initialize(table, style: Style::Definition.new,
                     continued: false, caption_text: nil)
        super(style: style)
        @table = table
        @continued = continued
        @caption_text = caption_text
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

        if @continued && @caption_text
          caption_h = emit_continuation_caption(x, cursor, width, boxes, context)
          cursor -= caption_h
          consumed += caption_h
        end

        header_rows, body_rows = partition_rows

        header_rows.each do |row|
          rh = row_height(row, cols, header: true)
          cursor -= rh
          consumed += rh
          render_row(row, x, cursor, cols, rh, boxes, context, header: true)
        end
        body_rows.each do |row|
          rh = row_height(row, cols, header: false)
          cursor -= rh
          consumed += rh
          render_row(row, x, cursor, cols, rh, boxes, context, header: false)
        end

        [boxes, consumed]
      end

      # Renders one row, advancing +cell_x+ by the natural cell width
      # (or colspan * unit width for spanning cells).
      def render_row(row, x, cursor, cols, rh, boxes, context, header:)
        cell_x = x.to_f
        ci = 0
        row.cells.each do |cell|
          span = [cell.colspan.to_i, 1].max
          span = [span, cols.length - ci].min
          cw = cols[ci, span].sum || (width_fallback(x, span))
          render_cell(cell, cell_x, cursor, cw, rh, boxes, context, header: header)
          cell_x += cw
          ci += span
        end
      end

      def width_fallback(_x, span)
        50.0 * span
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
          head = self.class.new(head_table, style: @style,
                                            continued: @continued,
                                            caption_text: @caption_text)
        else
          head = nil
        end

        tail_table = rebuild_table(header, tail_rows)
        tail = self.class.new(tail_table, style: @style,
                                          continued: true,
                                          caption_text: @caption_text)
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
        natural = max_h + 4.0
        [natural, row.min_height].max
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
                           style_id: @table.style_id, id: @table.id,
                           caption: @table.caption)
      end

      def emit_continuation_caption(x, y, width, boxes, _context)
        caption_style = @style.with(align: :left, font_size: @style.font_size)
        short_caption = short_caption_text
        tf = TextFlowable.new(
          [InlineRun.new("#{short_caption} (continued)", style: caption_style)],
          style: caption_style
        )
        line_h = tf.height(width)
        tboxes, = tf.emit(x, y, width, nil)
        boxes.concat(tboxes)
        line_h
      end

      def short_caption_text
        parts = @caption_text.split(CAPTION_DASH)
        return @caption_text if parts.length < 2

        parts.first.to_s
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
