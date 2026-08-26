# frozen_string_literal: true

module Arrolio
  module Flowables
    # A figure is atomic: the image and its caption never split
    # across a page boundary (FOP keep-together on figure blocks —
    # an orphaned caption at a page top is a rendering defect).
    class FigureFlowable < GroupFlowable
      def initialize(image, caption)
        super([image, caption])
      end

      def image = @parts.first
      def caption = @parts.last
    end
  end
end
