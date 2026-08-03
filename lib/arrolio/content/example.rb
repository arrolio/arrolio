# frozen_string_literal: true

module Arrolio
  module Content
    # A semantic example group. Same shape as Note but carries the
    # :example style_id by default so the flow builder can apply the
    # XSL's `example-body-style` margin-left to the body Paragraphs.
    class Example
      attr_reader :label, :body, :id, :style_id

      def initialize(body:, label: '', id: nil, style_id: :example)
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
