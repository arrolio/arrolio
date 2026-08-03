# frozen_string_literal: true

module Arrolio
  module Content
    # A semantic heading. Distinct from +Paragraph+ so the renderer
    # can emit PDF structure tags (for accessibility/ToC), the engine
    # can record heading → page mappings for cross-references, and the
    # FlowBuilder can apply distinct rendering rules (keep_together,
    # page-break-before, outline level).
    class Heading
      attr_reader :level, :number, :title, :id, :style_id

      def initialize(level:, title:, number: nil, id: nil, style_id: :heading_1)
        @level = level.to_i
        @number = number&.to_s
        @title = title.to_s
        @id = id&.to_s
        @style_id = style_id.to_sym
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          level == other.level &&
          number == other.number &&
          title == other.title &&
          id == other.id &&
          style_id == other.style_id
      end

      alias eql? ==

      def hash
        [self.class, level, number, title, id, style_id].hash
      end

      def inline_header?
        !number.nil? && title.empty?
      end
    end
  end
end
