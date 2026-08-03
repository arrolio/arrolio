# frozen_string_literal: true

module Arrolio
  module Content
    # A footnote reference in the content tree. Carries the marker
    # (e.g. "1", "a", "*") and the footnote body (paragraphs).
    # The adapter emits these from <fn> elements; the FlowBuilder
    # places the marker inline and defers the body to the page's
    # footnote zone (rendered at the bottom of the page).
    class Footnote
      attr_reader :marker, :body, :id, :style_id

      def initialize(marker:, body:, id: nil, style_id: :footnote)
        @marker = marker.to_s
        @body = Array(body).freeze
        @id = id&.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def body_text
        @body.map do |node|
          node.is_a?(Paragraph) ? node.text : node.to_s
        end.join(' ')
      end

      def empty?
        @marker.empty? && @body.empty?
      end

      def ==(other)
        other.is_a?(self.class) &&
          marker == other.marker &&
          body == other.body &&
          id == other.id &&
          style_id == other.style_id
      end

      alias eql? ==

      def hash
        [self.class, marker, body, id, style_id].hash
      end
    end
  end
end
