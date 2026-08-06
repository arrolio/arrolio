# frozen_string_literal: true

module Arrolio
  module Flowables
    # Text rendered at a fixed rotation around its baseline. Used
    # for cover layouts where vertical text runs along the page
    # edge (some flavors put the docidentifier + edition rotated
    # 90° on the left margin).
    #
    # +angle+ is in degrees, clockwise from horizontal. Common
    # values: 90 (text reads top-to-bottom), 270 (bottom-to-top).
    #
    # The flowable consumes zero vertical flow space (it's
    # absolutely positioned via PositionedBlock or similar) so
    # siblings continue normally.
    class RotatedText < Flowable
      attr_reader :text, :angle

      def initialize(text, style: Style::Definition.new, angle: 90)
        super(style: style)
        @text = text.to_s
        @angle = angle.to_f
      end

      def height(_width, _context = nil)
        GlyphMeasurer.new(font_name: @style.font_name)
                     .line_height(font_size: @style.font_size,
                                  line_spacing: @style.line_spacing)
      end

      def emit(x, y, width, _context = nil)
        line_h = height(width)
        measurer = GlyphMeasurer.new(font_name: @style.font_name)
        text_w = measurer.width_of_string(@text, font_size: @style.font_size)

        box = Output::PlacedBox.new(
          x: x, y: y - line_h,
          width: text_w, height: line_h,
          kind: :rotated_text,
          data: {
            text: @text,
            angle: @angle,
            line_height: line_h,
            style: @style
          }
        )
        [[box], 0.0]
      end
    end
  end
end
