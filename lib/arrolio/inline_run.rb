# frozen_string_literal: true

module Arrolio
  # One inline run within a paragraph: a contiguous span of text
  # sharing a single Style. A paragraph is laid out as a list of
  # InlineRun instances. Lives at the Layout level so that other
  # Layout modules (InlineBuilder, TextLayout, FO::Compiler) all
  # share the same type.
  #
  # Carries optional baseline_shift (:sub / :sup / nil) and
  # font_size_scale for subscript/superscript rendering, plus
  # optional href for hyperlink annotations.
  class InlineRun
    attr_reader :text, :style, :baseline_shift, :font_size_scale, :href

    def initialize(text, style: Style.new, baseline_shift: nil,
                   font_size_scale: 1.0, href: nil)
      @text = text.to_s
      @style = style
      @baseline_shift = baseline_shift
      @font_size_scale = font_size_scale.to_f
      @href = href
    end

    def empty?
      @text.empty?
    end

    def length
      @text.length
    end

    def width(measurer, font_size: style.font_size)
      measurer.width_of_run(
        @text,
        font_size: font_size * @font_size_scale,
        character_spacing: style.character_spacing,
        word_spacing: style.word_spacing
      )
    end

    def hyperlink?
      !@href.nil? && !@href.empty?
    end

    def ==(other)
      other.is_a?(self.class) &&
        text == other.text &&
        style == other.style &&
        baseline_shift == other.baseline_shift &&
        font_size_scale == other.font_size_scale &&
        href == other.href
    end

    def hash
      [text, style, baseline_shift, font_size_scale, href].hash
    end
  end
end
