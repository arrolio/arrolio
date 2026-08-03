# frozen_string_literal: true

module Arrolio
  module Content
    # A preformatted text block. Preserves whitespace (spaces, tabs,
    # newlines) and renders in monospace font without justification.
    # Used for code blocks, ASCII art, and any content where the
    # visual layout of whitespace matters.
    #
    # Each line becomes a separate inline run in the paragraph so
    # the renderer can apply line-by-line font metrics without the
    # greedy line breaker collapsing internal whitespace.
    class Preformatted
      attr_reader :lines, :language, :style_id, :id

      def initialize(lines, language: nil, style_id: :preformatted, id: nil)
        @lines = Array(lines).map(&:to_s).freeze
        @language = language&.to_s
        @style_id = style_id.to_sym
        @id = id&.to_s
        freeze
      end

      def text
        @lines.join("\n")
      end

      def empty?
        @lines.empty? || @lines.all?(&:empty?)
      end

      def ==(other)
        other.is_a?(self.class) &&
          lines == other.lines &&
          language == other.language &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, lines, language, style_id, id].hash
      end
    end
  end
end
