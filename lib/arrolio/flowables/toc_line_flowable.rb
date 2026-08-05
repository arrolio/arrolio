# frozen_string_literal: true

module Arrolio
  module Flowables
    # One ToC line: title + dot leader + page number, all on one
    # line. The title is left-aligned, the page number is
    # right-aligned, and the gap between is filled with dot leaders.
    #
    # Emits three PlacedBox values:
    #   1. text box for the title at x=0
    #   2. text box for the page number, right-aligned at x=width
    #   3. (optional) line box for the dot leader between them
    class TocLineFlowable < Flowable
      LEADER_CHAR = '.'
      LEADER_GAP = 4.0 # pt between title/page and the leader run

      attr_reader :title, :page_number, :level

      def initialize(title, page_number, level: 1, style: Style::Definition.new)
        super(style: style)
        @title = title.to_s
        @page_number = page_number.to_i
        @level = level.to_i
      end

      def height(_width, _context = nil)
        GlyphMeasurer.new(font_name: @style.font_name)
                     .line_height(font_size: @style.font_size,
                                  line_spacing: @style.line_spacing)
      end

      def emit(x, y, width, context = nil)
        measurer = GlyphMeasurer.new(font_name: @style.font_name)
        line_h = height(width, context)
        page_str = @page_number.to_s
        title_w = measurer.width_of_string(@title, font_size: @style.font_size)
        page_w = measurer.width_of_string(page_str, font_size: @style.font_size)
        page_x = x + width - page_w
        leader_w = page_x - (x + title_w + LEADER_GAP)

        boxes = []
        boxes.concat(emit_title(x, y, width, line_h, context))
        boxes.concat(emit_page_number(page_x, y, page_w, line_h, context))
        boxes.concat(emit_leader(x + title_w + LEADER_GAP, y, leader_w, line_h, measurer)) if leader_w.positive?
        [boxes, line_h]
      end

      private

      def emit_title(x, y, _width, line_h, context)
        tf = TextFlowable.new([InlineRun.new(@title, style: @style)],
                              style: @style.with(align: :left))
        boxes, _consumed = tf.emit(x, y, x_origin_width(@title, @style), context)
        position_boxes_at(boxes, x, y, line_h)
      end

      def emit_page_number(page_x, y, page_w, _line_h, context)
        tf = TextFlowable.new([InlineRun.new(@page_number.to_s, style: @style)],
                              style: @style.with(align: :left))
        boxes, _consumed = tf.emit(page_x, y, page_w, context)
        boxes
      end

      def emit_leader(start_x, y, leader_w, _line_h, measurer)
        dot_w = measurer.width_of_string(LEADER_CHAR, font_size: @style.font_size)
        count = (leader_w / dot_w).floor
        return [] if count <= 0

        leader_text = LEADER_CHAR * count
        tf = TextFlowable.new([InlineRun.new(leader_text, style: @style)],
                              style: @style.with(align: :left))
        boxes, _consumed = tf.emit(start_x, y, leader_w, nil)
        boxes
      end

      # TextFlowable.width is the natural width of the text; for the
      # title box we want exactly the title width so the leader
      # starts right after.
      def x_origin_width(text, style)
        GlyphMeasurer.new(font_name: style.font_name)
                     .width_of_string(text, font_size: style.font_size)
      end

      # The TextFlowable emits a single box for a single-line
      # paragraph; trust that and return as-is. (No-op retained for
      # symmetry with future flowables that may need offset
      # adjustment.)
      def position_boxes_at(boxes, _x, _y, _line_h)
        boxes
      end
    end
  end
end
