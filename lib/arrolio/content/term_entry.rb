# frozen_string_literal: true

module Arrolio
  module Content
    # A dictionary term entry: optional number, preferred term text,
    # definition Paragraphs, and optional source citation. Maps to
    # the `<term>` element in standoc vocabulary. Renders as a
    # hanging-indent group in the flow builder.
    class TermEntry
      attr_reader :number, :preferred, :definition, :source, :id, :style_id

      def initialize(number: nil, preferred: nil, definition: [],
                     source: nil, id: nil, style_id: :term)
        @number = number&.to_s
        @preferred = preferred
        @definition = Array(definition).freeze
        @source = source
        @id = id&.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def empty?
        @preferred.nil? && @definition.empty? && @number.nil?
      end

      def ==(other)
        other.is_a?(self.class) &&
          number == other.number &&
          preferred == other.preferred &&
          definition == other.definition &&
          source == other.source &&
          id == other.id &&
          style_id == other.style_id
      end
      alias eql? ==

      def hash
        [self.class, number, preferred, definition, source, id, style_id].hash
      end
    end
  end
end
