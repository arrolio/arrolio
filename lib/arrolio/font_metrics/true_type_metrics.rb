# frozen_string_literal: true

require 'fontisan'

module Arrolio
  module FontMetrics
    # Glyph-width lookup from a TrueType/OpenType font file.
    # Reads head, hhea, hmtx, cmap, OS/2 tables via Fontisan.
    # Same interface as AfmMetrics so callers can swap freely.
    class TrueTypeMetrics
      attr_reader :font_name, :fontisan_font

      def initialize(font_name, fontisan_font)
        @font_name = font_name.to_s
        @fontisan_font = fontisan_font
        @cmap = fontisan_font.table('cmap')
        @unicode_to_gid = @cmap ? @cmap.unicode_mappings.transform_keys(&:to_i) : {}
        @head = fontisan_font.table('head')
        @hhea = fontisan_font.table('hhea')
        @os2 = fontisan_font.table('OS/2')
        @hmtx = fontisan_font.table('hmtx')
        parse_hmtx
      end

      def parse_hmtx
        return unless @hmtx && @hhea

        maxp = @fontisan_font.table('maxp')
        num_metrics = @hhea.number_of_h_metrics rescue nil
        num_glyphs = maxp&.num_glyphs
        return unless num_metrics && num_glyphs

        @hmtx.parse_with_context(num_metrics, num_glyphs)
      rescue StandardError
        nil
      end

      def self.from_file(font_name, path)
        font = Fontisan::FontLoader.load(path)
        new(font_name, font)
      end

      def units_per_em
        @head ? @head.units_per_em : 1000
      rescue StandardError
        1000
      end

      def advance_width(char)
        gid = @unicode_to_gid[char.ord]
        return 0 unless gid && @hmtx

        metric = @hmtx.metric_for(gid)
        metric ? metric[:advance_width] : 0
      rescue StandardError
        0
      end

      def width_of_string(str, font_size:)
        scale = font_size.to_f / units_per_em
        str.each_char.sum { |c| advance_width(c) * scale }
      end

      def ascender(font_size: 12)
        return font_size * 0.8 unless @hhea

        ((@hhea.ascender || 800).to_f / units_per_em) * font_size.to_f
      rescue StandardError
        font_size * 0.8
      end

      def descender(font_size: 12)
        return -font_size * 0.2 unless @hhea

        ((@hhea.descender || -200).to_f / units_per_em) * font_size.to_f
      rescue StandardError
        -font_size * 0.2
      end

      def cap_height(font_size: 12)
        return font_size * 0.7 unless @os2

        ((@os2.cap_height || 700).to_f / units_per_em) * font_size.to_f
      rescue StandardError
        font_size * 0.7
      end

      def line_height(font_size:, line_spacing: 1.2)
        # CSS/XSL convention: line-height is a multiplier of font-size,
        # NOT derived from the font ascender/descender ratio.
        font_size.to_f * line_spacing.to_f
      end
    end
  end
end
