# frozen_string_literal: true

module Arrolio
  # Unicode text direction detection for BIDI-aware layout. Detects
  # whether a string is predominantly left-to-right (Latin, CJK),
  # right-to-left (Arabic, Hebrew), or mixed. Used by the text
  # layout engine to apply correct character ordering within lines.
  #
  # This module implements the "paragraph level" detection from
  # Unicode UAX #9 (BIDI Algorithm) — a simplified version that
  # suffices for most standards documents. Full BIDI reordering
  # (handling embedded runs, override controls) is future work.
  module TextDirection
    LTR = :ltr
    RTL = :rtl
    MIXED = :mixed

    # Unicode blocks containing RTL characters.
    RTL_RANGES = [
      0x0590..0x05FF,   # Hebrew
      0x0600..0x06FF,   # Arabic
      0x0700..0x074F,   # Syriac
      0x0750..0x077F,   # Arabic Supplement
      0x08A0..0x08FF,   # Arabic Extended-A
      0xFB1D..0xFB4F,   # Hebrew Presentation Forms
      0xFB50..0xFDFF,   # Arabic Presentation Forms-A
      0xFE70..0xFEFF    # Arabic Presentation Forms-B
    ].freeze

    module_function

    # Returns the dominant direction of a string.
    # +:ltr+ — all or predominantly LTR characters.
    # +:rtl+ — predominantly RTL characters.
    # +:mixed+ — significant presence of both LTR and RTL.
    def detect(string)
      return LTR if string.nil? || string.empty?

      chars = string.each_char.to_a
      rtl_count = chars.count { |c| rtl?(c) }
      ltr_count = chars.count { |c| ltr?(c) }

      return LTR if rtl_count.zero?
      return RTL if ltr_count.zero?

      ratio = rtl_count.to_f / (rtl_count + ltr_count)
      ratio > 0.6 ? RTL : (ratio < 0.3 ? LTR : MIXED)
    end

    # Is this character an RTL character?
    def rtl?(char)
      cp = char.ord
      RTL_RANGES.any? { |range| range.cover?(cp) }
    end

    # Is this character an LTR character (Latin, Cyrillic, Greek,
    # CJK, etc.)? Excludes whitespace, punctuation, and digits
    # (which are neutral in BIDI).
    def ltr?(char)
      cp = char.ord
      return false if cp < 0x0041  # below 'A'
      return false if rtl?(char)
      return false if neutral?(char)

      # Latin, Latin Extended, Cyrillic, Greek, CJK, etc.
      true
    end

    # BIDI-neutral characters (whitespace, punctuation, digits).
    def neutral?(char)
      char.match?(/\s/) || char.match?(/[0-9]/) || char.match?(/[^\p{L}]/)
    end

    # Reverses a string character-by-character for RTL rendering.
    # Does NOT do full BIDI reordering — only flips the base
    # direction. Adequate for simple RTL text without embedded LTR.
    def reverse_for_rtl(string)
      string.reverse
    end
  end
end
