# frozen_string_literal: true

module Arrolio
  module FontMetrics
    # Glyph-width lookup against Pdfrb's AFM data for one of the 14
    # PDF standard Type1 fonts.
    class AfmMetrics
      UNITS_PER_EM = 1000

      attr_reader :font_name, :afm

      def initialize(font_name, afm)
        @font_name = font_name.to_s
        @afm = afm
      end

      def self.for_name(name)
        afm = Pdfrb::Font::Type1::FontMetrics.for_standard_font(name.to_s)
        return nil unless afm

        new(name, afm)
      end

      def units_per_em
        UNITS_PER_EM
      end

      def advance_width(char)
        metric = metric_for(char)
        metric ? metric[:width] : 0
      end

      def width_of_string(str, font_size:)
        scale = font_size.to_f / units_per_em
        str.each_char.sum { |c| advance_width(c) * scale }
      end

      def ascender(font_size: 12)
        (afm.ascender || 800) * font_size.to_f / units_per_em
      end

      def descender(font_size: 12)
        (afm.descender || -200) * font_size.to_f / units_per_em
      end

      def cap_height(font_size: 12)
        (afm.cap_height || 700) * font_size.to_f / units_per_em
      end

      def line_height(font_size:, line_spacing: 1.2)
        ((afm.ascender || 800).to_f - (afm.descender || -200).to_f) *
          font_size.to_f / units_per_em * line_spacing.to_f
      end

      private

      def metric_for(char)
        codepoint = char.ord
        if codepoint < 0x80
          m = afm.metrics.char_metrics[codepoint]
          return m if m
        end

        name = glyph_name_for(char)
        afm.metrics.char_metrics[name] if name
      end

      def glyph_name_for(char)
        @glyph_name_cache ||= {}
        return @glyph_name_cache[char] if @glyph_name_cache.key?(char)

        @glyph_name_cache[char] = unicode_to_name[char.ord]
      end

      def unicode_to_name
        return @unicode_to_name if @unicode_to_name

        table = Pdfrb::Font::GlyphList.table
        @unicode_to_name = {}
        table.each do |gname, str|
          cp = str.ord
          @unicode_to_name[cp] ||= gname if cp
        end
        (0x21..0x7E).each do |cp|
          @unicode_to_name[cp] ||= cp.chr
        end
        @unicode_to_name
      end
    end
  end
end
