# frozen_string_literal: true

module Arrolio
  module Content
    # A form field for interactive PDF AcroForm. Carries the field
    # type, name, value, and geometry. The renderer emits it as a
    # PDAcroForm widget (text field, checkbox, radio button) during
    # post-processing. This model captures the semantic intent;
    # the actual PDF widget creation is a renderer post-pass.
    class FormField
      TYPES = %i[text checkbox radio signature].freeze

      attr_reader :type, :name, :value, :page_number,
                  :x, :y, :width, :height, :style_id

      def initialize(type:, name:, page_number:, x:, y:, width:, height:, value: nil, style_id: :form_field)
        @type = type.to_sym
        @name = name.to_s
        @value = value
        @page_number = page_number.to_i
        @x = x.to_f
        @y = y.to_f
        @width = width.to_f
        @height = height.to_f
        @style_id = style_id.to_sym
        freeze
      end

      def text? = @type == :text
      def checkbox? = @type == :checkbox
      def radio? = @type == :radio

      def ==(other)
        other.is_a?(self.class) &&
          type == other.type && name == other.name &&
          value == other.value && page_number == other.page_number &&
          x == other.x && y == other.y &&
          width == other.width && height == other.height
      end
      alias eql? ==

      def hash
        [self.class, type, name, value, page_number, x, y, width, height].hash
      end
    end
  end
end
