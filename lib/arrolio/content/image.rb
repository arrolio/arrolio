# frozen_string_literal: true

module Arrolio
  module Content
    class Image
      attr_reader :src, :width, :height, :alt, :style_id, :id

      def initialize(src, width: nil, height: nil, alt: nil,
                     style_id: :figure_image, id: nil)
        @src = src.to_s
        @width = width&.to_f
        @height = height&.to_f
        @alt = alt
        @style_id = style_id.to_sym
        @id = id
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          src == other.src &&
          width == other.width &&
          height == other.height &&
          alt == other.alt &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, src, width, height, alt, style_id, id].hash
      end
    end
  end
end
