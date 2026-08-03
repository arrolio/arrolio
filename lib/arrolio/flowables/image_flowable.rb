# frozen_string_literal: true

module Arrolio
  module Flowables
    # Renders a PNG / JPEG / SVG via Pdfrb's image registry. Scales
    # to +display_width+ while preserving aspect ratio; if
    # +display_width+ is nil, scales to fit the available width.
    #
    # Image registration is deferred to the render pass: the PlacedBox
    # carries the source path, and the renderer resolves it (including
    # SVG-to-PNG rasterization if needed) when it walks the page tree.
    class ImageFlowable < Flowable
      attr_reader :src, :natural_width, :natural_height, :display_width, :alt

      def initialize(src, natural_width:, natural_height:,
                     display_width: nil, alt: nil,
                     style: Style::Definition.new)
        super(style: style)
        @src = src.to_s
        @natural_width = natural_width.to_f
        @natural_height = natural_height.to_f
        @display_width = display_width
        @alt = alt
      end

      def height(width, _context = nil)
        return 0.0 if @natural_width.zero?

        actual_w = actual_width(width)
        actual_w * (@natural_height / @natural_width)
      end

      def emit(x, y, width, _context = nil)
        return [[], 0.0] if @natural_width.zero?

        actual_w = actual_width(width)
        actual_h = actual_w * (@natural_height / @natural_width)
        box = Output::PlacedBox.image(
          x: x, y: y - actual_h,
          width: actual_w, height: actual_h,
          image_ref: @src
        )
        [[box], actual_h]
      end

      private

      def actual_width(width)
        @display_width && @display_width < width ? @display_width : width
      end
    end
  end
end
