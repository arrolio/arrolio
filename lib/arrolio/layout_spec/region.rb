# frozen_string_literal: true

module Arrolio
  class LayoutSpec
    # Named rectangle within a PageTemplate. The five standard
    # regions are +:body+, +:before+ (header), +:after+ (footer),
    # +:start+ (left), +:end+ (right). Pure geometry; runtime
    # consumed state lives in Frame.
    class Region
      attr_reader :name, :x, :y, :width, :height

      def initialize(name:, x:, y:, width:, height:)
        @name = name.to_sym
        @x = x.to_f
        @y = y.to_f
        @width = width.to_f
        @height = height.to_f
        freeze
      end

      def area
        @width * @height
      end

      def ==(other)
        other.is_a?(self.class) &&
          name == other.name && x == other.x && y == other.y &&
          width == other.width && height == other.height
      end

      alias eql? ==

      def hash
        [self.class, name, x, y, width, height].hash
      end
    end
  end
end
