# frozen_string_literal: true

module Arrolio
  module Flowables
    # A figure is atomic: the image and its caption never split
    # across a page boundary (FOP keep-together on figure blocks —
    # an orphaned caption at a page top is a rendering defect).
    class FigureFlowable < Flowable
      attr_reader :image, :caption

      def initialize(image, caption, style: Style::Definition.new(keep_together: true))
        super(style: style)
        @image = image
        @caption = caption
      end

      def height(width, context = nil)
        @image.height(width, context) + @caption.height(width, context)
      end

      def emit(x, y, width, context = nil)
        boxes = []
        image_h = @image.height(width, context)
        image_boxes, = @image.emit(x, y, width, context)
        boxes.concat(image_boxes)
        caption_boxes, caption_h = @caption.emit(x, y - image_h, width, context)
        boxes.concat(caption_boxes)
        [boxes, image_h + caption_h]
      end
    end
  end
end
