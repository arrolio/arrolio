# frozen_string_literal: true

module Arrolio
  module Content
    # A formula — MathML root + rendered text fallback. Carries the
    # math structure separately from how it's rendered (text fallback
    # today, proper math typesetting in the future). The renderer can
    # later use the MathML for accessible representation while the
    # fallback provides visual rendering.
    class Formula
      attr_reader :mathml, :text_fallback, :style_id

      def initialize(mathml:, text_fallback:, style_id: :body)
        @mathml = mathml.to_s
        @text_fallback = text_fallback.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          mathml == other.mathml &&
          text_fallback == other.text_fallback &&
          style_id == other.style_id
      end

      alias eql? ==

      def hash
        [self.class, mathml, text_fallback, style_id].hash
      end
    end
  end
end
