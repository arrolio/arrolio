# frozen_string_literal: true

module Arrolio
  module Font
    # Converts a Unicode string into a 2-byte-big-endian
    # glyph-ID sequence for an Identity-H-encoded CIDFont.
    class TextEncoder
      attr_reader :embedder

      def initialize(embedder)
        @embedder = embedder
      end

      # Returns a binary-encoded String of 2-byte GIDs for the
      # codepoints in +text+. The renderer passes this to
      # +canvas.text+ instead of the Unicode string.
      def encode(text)
        bytes = String.new.force_encoding(Encoding::BINARY)
        text.each_codepoint do |cp|
          gid = @embedder.subset_gid_for_codepoint(cp)
          bytes << (gid >> 8).chr(Encoding::BINARY)
          bytes << (gid & 0xff).chr(Encoding::BINARY)
        end
        bytes
      end
    end
  end
end
