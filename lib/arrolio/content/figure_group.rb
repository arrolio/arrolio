# frozen_string_literal: true

module Arrolio
  module Content
    # A figure group: optional Image plus optional caption Paragraph.
    # Replaces the previous flat [Image, Paragraph] emission from
    # convert_figure. The flow builder renders the group as a
    # keep-together unit so the caption never lands on a different
    # page from the image.
    class FigureGroup
      attr_reader :image, :caption, :id, :style_id

      def initialize(image: nil, caption: nil, id: nil, style_id: :figure)
        @image = image
        @caption = caption
        @id = id&.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def empty?
        @image.nil? && (@caption.nil? || (@caption.is_a?(Paragraph) && @caption.empty?))
      end

      def ==(other)
        other.is_a?(self.class) &&
          image == other.image &&
          caption == other.caption &&
          id == other.id &&
          style_id == other.style_id
      end
      alias eql? ==

      def hash
        [self.class, image, caption, id, style_id].hash
      end
    end
  end
end
