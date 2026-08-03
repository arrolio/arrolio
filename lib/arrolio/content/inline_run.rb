# frozen_string_literal: true

module Arrolio
  module Content
    # A single inline run of text within a paragraph. Carries the
    # +text+ to render, the +style_id+ for visual styling (bold,
    # italic, etc.), optional +href+ for hyperlinks, and optional
    # +baseline_shift+ / +font_size_scale+ for subscript/superscript
    # positioning (used by MathML msub/msup rendering).
    class InlineRun
      BASELINE_NORMAL = nil
      BASELINE_SUB = :sub
      BASELINE_SUP = :sup

      attr_reader :text, :style_id, :href, :baseline_shift, :font_size_scale

      def initialize(text, style_id: :inline, href: nil,
                     baseline_shift: BASELINE_NORMAL, font_size_scale: 1.0)
        @text = text.to_s
        @style_id = style_id.to_sym
        @href = href
        @baseline_shift = baseline_shift
        @font_size_scale = font_size_scale.to_f
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          text == other.text &&
          style_id == other.style_id &&
          href == other.href &&
          baseline_shift == other.baseline_shift &&
          font_size_scale == other.font_size_scale
      end

      alias eql? ==

      def hash
        [self.class, text, style_id, href, baseline_shift, font_size_scale].hash
      end

      def subscript?
        @baseline_shift == BASELINE_SUB
      end

      def superscript?
        @baseline_shift == BASELINE_SUP
      end
    end
  end
end
