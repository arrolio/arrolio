# frozen_string_literal: true

module Arrolio
  module Flowables
    # Real table layout driven by Table::Grid: colspan and rowspan
    # aware cell placement, per-flavor row minimum height, vertical
    # alignment inside cells, borders per cell, header row repeat,
    # continuation caption on split, and table footnotes rendered
    # below the last row.
    class TableFlowable < Flowable
      attr_reader :table, :continued, :caption_text, :caption_runs, :grid,
                  :min_row_height, :cell_padding, :footnote_font_size

      CAPTION_DASH = Regexp.new("[\u00A0\u2009\u0020]\u2014").freeze
      FOOTNOTE_SPACING = 10.0

      def initialize(table, style: Style::Definition.new,
                     continued: false, caption_text: nil, caption_runs: nil,
                     caption_style: nil, min_row_height: 0.0,
                     cell_padding: 2.0, footnote_font_size: nil)
        super(style: style)
        @table = table
        @continued = continued
        @caption_runs = caption_runs
        @caption_text = caption_text || caption_runs&.map(&:text)&.join
        @caption_style = caption_style
        @min_row_height = min_row_height.to_f
        @cell_padding = cell_padding.to_f
        @footnote_font_size = footnote_font_size ||
                              (@style.font_size * 0.9).round(1)
        @grid = Table::Grid.build(table)
      end

      def height(width, _context = nil)
        cols = column_widths_for(width)
        caption_height(width) + row_heights(cols).sum +
          footnote_block_height(width, cols)
      end

      def emit(x, y, width, _context = nil)
        cols = column_widths_for(width)
        heights = row_heights(cols)
        boxes = []
        consumed = 0.0
        cursor = y

        # The caption travels with the table: the head part draws the
        # full caption, continuations draw the short form. This keeps
        # the caption from being orphaned at the bottom of a page.
        if @caption_text
          caption_h = emit_caption(x, cursor, width, boxes)
          cursor -= caption_h
          consumed += caption_h
        end

        row_bottoms = row_bottom_positions(cursor, heights)
        grid.placements.each do |placement|
          cell_y = row_bottoms[placement.row_index + placement.rowspan - 1]
          cell_h = heights[placement.row_index, placement.rowspan].sum
          cell_w = column_span_width(cols, placement)
          cell_x = x + cols[0, placement.column_index].sum
          render_cell(placement.cell, cell_x, cell_y, cell_w, cell_h, boxes,
                      header: header_row?(placement.row_index))
        end
        consumed += heights.sum
        cursor = row_bottoms[-1] || cursor

        fn_h = emit_footnotes(x, cursor, width, cols, boxes)
        consumed += fn_h

        [boxes, consumed]
      end

      def splittable?
        true
      end

      # Splits at welded-group boundaries only — a rowspan cell is
      # never cut by a page break. When the first group already
      # exceeds the remaining space, no head is returned and the
      # engine moves the whole table to the next page. Footnotes
      # travel with the part carrying the last body row.
      def do_split(width, remaining_height, _context = nil)
        cols = column_widths_for(width)
        heights = row_heights(cols)
        header, body = partition_rows
        header_count = header.length

        head_groups = []
        tail_groups = []
        # The head part also carries the caption and the repeated
        # header rows — they consume the same budget as body rows.
        used = caption_height(width) + heights[0, header_count].sum
        body_row_groups.each do |group|
          group_h = heights[group.first, group.length].sum
          if used + group_h <= remaining_height
            head_groups << group
            used += group_h
          else
            tail_groups << group
          end
        end

        head_rows = head_groups.flat_map { |g| body[g.first - header_count, g.length] }
        tail_rows = tail_groups.flat_map { |g| body[g.first - header_count, g.length] }

        return [nil, whole_table_copy] if head_rows.empty?
        if tail_rows.empty?
          return [build_split(header, head_rows, @continued,
                              footnotes: @table.footnotes), nil]
        end

        [build_split(header, head_rows, @continued, footnotes: []),
         build_split(header, tail_rows, true, footnotes: @table.footnotes)]
      end

      def whole_table_copy
        build_split(@table.header, @table.body, @continued,
                    footnotes: @table.footnotes)
      end

      private

      def rows
        @table.rows
      end

      def partition_rows
        [@table.header, @table.body]
      end

      def header_row?(row_index)
        row_index < @table.header.length
      end

      # Body row groups in ABSOLUTE row indexes, welded together by
      # rowspan spans so a split never cuts through a vertical span.
      # Groups that reach into the header are clipped to the body
      # range — the span still welds the body rows it covers, and the
      # header repeats on every continuation part anyway.
      def body_row_groups
        header_count = @table.header.length
        total = rows.length
        return [] if header_count >= total

        grid.atomic_row_groups
            .map { |group| group.select { |r| r >= header_count } }
            .reject(&:empty?)
            .map(&:freeze)
      end

      def build_split(header, body_rows, continued, footnotes:)
        table = Content::Table.new(
          header: header, body: body_rows,
          column_widths: @table.column_widths,
          style_id: @table.style_id, id: @table.id,
          caption: @table.caption,
          footnotes: footnotes || []
        )
        self.class.new(table, style: @style, continued: continued,
                              caption_text: @caption_text,
                              caption_style: @caption_style,
                              min_row_height: @min_row_height,
                              cell_padding: @cell_padding,
                              footnote_font_size: @footnote_font_size)
      end

      def column_widths_for(width)
        return Array.new(grid.column_count, width.to_f / [grid.column_count, 1].max) if grid.column_count.zero?

        @cached_widths ||= Table::AutoLayout.new(@table,
                                                 available_width: width,
                                                 grid: grid).compute
      end

      def column_span_width(cols, placement)
        cols[placement.column_index, placement.colspan].sum ||
          (50.0 * placement.colspan)
      end

      def inner_width(cols, placement)
        column_span_width(cols, placement) - (@cell_padding * 2)
      end

      # Row heights: single-row cells drive their row's height; a
      # multi-row cell that does not fit in the spanned rows pushes
      # the deficit into every spanned row equally. Every row obeys
      # the flavor's minimum height and its own min-height attribute.
      def row_heights(cols)
        heights = Array.new(rows.length, 0.0)
        grid.placements.each do |placement|
          next if placement.spans_multiple_rows?

          content = cell_content_height(placement.cell,
                                        inner_width(cols, placement),
                                        header: header_row?(placement.row_index))
          heights[placement.row_index] = [heights[placement.row_index], content].max
        end

        heights.each_with_index do |h, row_index|
          floors = [@min_row_height, rows[row_index].min_height]
          heights[row_index] = [h + (@cell_padding * 2), *floors].max
        end

        grid.placements.each do |placement|
          next unless placement.spans_multiple_rows?

          spanned = heights[placement.row_index, placement.rowspan]
          content = cell_content_height(placement.cell,
                                        inner_width(cols, placement),
                                        header: header_row?(placement.row_index)) +
                    (@cell_padding * 2)
          deficit = content - spanned.sum
          next unless deficit.positive?

          share = deficit / placement.rowspan
          placement.rowspan.times do |r|
            heights[placement.row_index + r] += share
          end
        end
        heights
      end

      def row_bottom_positions(top, heights)
        bottoms = []
        cursor = top
        heights.each do |h|
          cursor -= h
          bottoms << cursor
        end
        bottoms
      end

      def cell_content_height(cell, width, header: false)
        style = cell_style(header: header)
        runs = cell_paragraph_runs(cell, style)
        return 0.0 if runs.empty?

        TextFlowable.new(runs, style: style).height(width)
      end

      def cell_paragraph_runs(cell, style)
        runs = []
        cell.content.each do |node|
          next unless node.is_a?(Content::Paragraph)

          runs.concat(node.inline_runs.map { |r| InlineRun.new(r.text, style: style) })
        end
        runs
      end

      def render_cell(cell, x, y, w, h, boxes, header: false)
        style = cell_style(header: header)
        style = style.with(align: cell.align) if cell.align
        runs = cell_paragraph_runs(cell, style)
        unless runs.empty?
          tf = TextFlowable.new(runs, style: style)
          inner_w = w - (@cell_padding * 2)
          content_h = tf.height(inner_w)
          text_top = text_top_for(cell, y, h, content_h)
          tboxes, = tf.emit(x + @cell_padding, text_top, inner_w, nil)
          boxes.concat(tboxes)
        end
        stroke = header ? 0.7 : 0.5
        boxes << Output::PlacedBox.rect(x: x, y: y, width: w, height: h,
                                        stroke_width: stroke, stroke_color: 'black')
      end

      # Vertical placement of cell content. Default (and :top) hugs
      # the cell's top padding; :middle and :bottom center or sink
      # the content block within the cell.
      def text_top_for(cell, cell_y, cell_h, content_h)
        slack = [cell_h - content_h - (@cell_padding * 2), 0.0].max
        lift = case cell.valign
               when :middle then slack / 2.0
               when :bottom then slack
               else 0.0
               end
        cell_y + cell_h - @cell_padding - lift
      end

      def footnote_block_height(width, _cols)
        return 0.0 if @table.footnotes.empty?

        FOOTNOTE_SPACING +
          @table.footnotes.sum { |fn| footnote_flowable(fn).height(width) }
      end

      def emit_footnotes(x, y, width, _cols, boxes)
        return 0.0 if @table.footnotes.empty?

        cursor = y - FOOTNOTE_SPACING
        consumed = FOOTNOTE_SPACING
        @table.footnotes.each do |fn|
          tf = footnote_flowable(fn)
          tboxes, = tf.emit(x, cursor, width, nil)
          boxes.concat(tboxes)
          h = tf.height(width)
          cursor -= h
          consumed += h
        end
        consumed
      end

      def footnote_flowable(fn)
        style = @style.with(font_size: @footnote_font_size, align: :left,
                            margin_top: 0.0, margin_bottom: 2.0)
        runs = [InlineRun.new("#{fn.marker} ", style: style)]
        fn.body.each do |node|
          next unless node.is_a?(Content::Paragraph)

          runs.concat(node.inline_runs.map { |r| InlineRun.new(r.text, style: style) })
        end
        TextFlowable.new(runs, style: style)
      end

      def emit_caption(x, y, width, boxes)
        runs = if @continued
                 text = "#{short_caption_text} (continued)"
                 [InlineRun.new(text, style: caption_style)]
               elsif @caption_runs
                 @caption_runs
               else
                 [InlineRun.new(@caption_text, style: caption_style)]
               end
        tf = TextFlowable.new(runs, style: caption_style)
        line_h = tf.height(width)
        tboxes, = tf.emit(x, y, width, nil)
        boxes.concat(tboxes)
        line_h
      end

      def caption_style
        @caption_style || @style.with(align: :left)
      end

      def caption_height(width)
        return 0.0 if @caption_text.nil?

        caption_flowable(width).height(width)
      end

      def caption_flowable(_width)
        runs = @caption_runs || [InlineRun.new(@caption_text, style: caption_style)]
        TextFlowable.new(runs, style: caption_style)
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

        base.with(font_name: "#{base.font_name} Bold")
      end
    end
  end
end
