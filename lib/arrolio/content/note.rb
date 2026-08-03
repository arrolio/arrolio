# frozen_string_literal: true

module Arrolio
  module Content
    # A semantic note group: optional label ("NOTE 1", "WARNING") plus
    # one or more body Paragraphs. Distinct from a bare Paragraph
    # because the flow builder renders it with a hanging indent and
    # the label in a marker column (matching the XSL's fo:list-block
    # rendering for notes/examples).
    #
    # Wraps the legacy Paragraph-with-`:note`-style emission so flavors
    # see richer structure without breaking older flow builders.
    class Note
      attr_reader :label, :body, :id, :style_id

      def initialize(body:, label: '', id: nil, style_id: :note)
        @label = label.to_s
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
        @body.empty? || @body.all? { |node| node.is_a?(Paragraph) && node.empty? }
      end

      def ==(other)
        other.is_a?(self.class) &&
          label == other.label &&
          body == other.body &&
          id == other.id &&
          style_id == other.style_id
      end
      alias eql? ==

      def hash
        [self.class, label, body, id, style_id].hash
      end
    end
  end
end
