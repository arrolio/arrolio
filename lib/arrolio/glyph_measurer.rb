# frozen_string_literal: true

module Arrolio
  # High-level facade over FontMetrics. Used by TextLayout,
  # TableLayout, ImageFlowable, etc. — anything that needs to ask
  # "how wide is this string at this size in this font?".
  #
  # Encapsulates the relationship between character_spacing (Tc),
  # word_spacing (Tw), and the underlying glyph widths — matches
  # what the renderer actually emits.
  class GlyphMeasurer
    attr_reader :font_name, :metrics

    def initialize(font_name:, style: :regular)
      @font_name = font_name.to_s
      @style = style
      @metrics = ::Arrolio::FontMetrics::Registry[@font_name]
    end

    def available?
      !@metrics.nil?
    end

    def width_of_string(str, font_size:)
      return estimate(str, font_size) unless available?

      @metrics.width_of_string(str, font_size: font_size)
    end

    # Width of a run including character_spacing (Tc — extra space
    # added after every glyph) and word_spacing (Tw — extra space
    # added after every space glyph). Matches PDF rendering rules.
    def width_of_run(str, font_size:, character_spacing: 0, word_spacing: 0)
      base = width_of_string(str, font_size: font_size)
      char_count = str.length
      word_count = str.count('  ')
      extra = (character_spacing.to_f * [char_count - 1, 0].max) +
        (word_spacing.to_f * word_count)
      base + extra
    end

    def advance_width(char, font_size:)
      return estimate(char, font_size) unless available?

      @metrics.advance_width(char) * font_size.to_f / @metrics.units_per_em
    end

    def ascender(font_size:) = @metrics&.ascender(font_size: font_size) || (font_size * 0.8)
    def descender(font_size:) = @metrics&.descender(font_size: font_size) || -(font_size * 0.2)
    def cap_height(font_size:) = @metrics&.cap_height(font_size: font_size) || (font_size * 0.7)

    def line_height(font_size:, line_spacing: 1.2)
      return font_size * 1.2 unless available?

      @metrics.line_height(font_size: font_size, line_spacing: line_spacing)
    end

    def space_width(font_size:)
      advance_width(' ', font_size: font_size)
    end

    private

    # Fallback when no metrics are loaded for the font. Same
    # formula the original Layout::TextBox used — keeps the layout
    # engine usable for unknown fonts, at the cost of accuracy.
    def estimate(str, font_size)
      str.length * font_size.to_f * 0.5
    end
  end
end
