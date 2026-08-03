# frozen_string_literal: true

module Arrolio
  module Output
    class Region
      attr_reader :name, :x, :y, :width, :height, :placed_boxes

      def initialize(name:, x:, y:, width:, height:, placed_boxes: [])
        @name = name.to_sym
        @x = x.to_f
        @y = y.to_f
        @width = width.to_f
        @height = height.to_f
        @placed_boxes = Array(placed_boxes).freeze
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          name == other.name && x == other.x && y == other.y &&
          width == other.width && height == other.height &&
          placed_boxes == other.placed_boxes
      end

      alias eql? ==

      def hash
        [self.class, name, x, y, width, height, placed_boxes].hash
      end
    end
  end
end
