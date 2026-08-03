# frozen_string_literal: true

module Arrolio
  class LayoutSpec
    class ScaleLength
      attr_reader :base_value, :scale_factor

      def initialize(base_value:, scale_factor: 1.0)
        @base_value = base_value.to_f
        @scale_factor = scale_factor.to_f
        freeze
      end

      def resolved
        @base_value * @scale_factor
      end

      def with_scale(factor)
        self.class.new(base_value: @base_value, scale_factor: factor)
      end

      def ==(other)
        other.is_a?(self.class) &&
          base_value == other.base_value &&
          scale_factor == other.scale_factor
      end
      alias eql? ==

      def hash
        [self.class, base_value, scale_factor].hash
      end
    end
  end
end
