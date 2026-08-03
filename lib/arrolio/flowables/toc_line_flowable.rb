# frozen_string_literal: true

module Arrolio
  module Flowables
    # One ToC line: title + dot-leader + page number. One line tall.
    class TocLineFlowable < Flowable
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
        page_str = @page_number.to_s
        measurer = GlyphMeasurer.new(font_name: @style.font_name)
        title_w = measurer.width_of_string(@title, font_size: @style.font_size)
        page_w = measurer.width_of_string(page_str, font_size: @style.font_size)
        gap = width - title_w - page_w - 10
        dots = gap.positive? ? ('.' * (gap / measurer.space_width(font_size: @style.font_size)).floor) : ' '
        text = "#{@title} #{dots} #{page_str}"
        tf = TextFlowable.new([InlineRun.new(text, style: @style)], style: @style)
        tf.emit(x, y, width, context)
      end
    end
  end
end
