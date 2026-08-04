# frozen_string_literal: true

module Arrolio
  module Content
    class Paragraph
      attr_reader :inline_runs, :style_id, :id, :footnote_refs

      def initialize(inline_runs = [], style_id: :body, id: nil, footnote_refs: [])
        @inline_runs = Array(inline_runs).freeze
        @style_id = style_id.to_sym
        @id = id
        @footnote_refs = Array(footnote_refs).freeze
        freeze
      end

      def text
        @inline_runs.map(&:text).join
      end

      def empty?
        @inline_runs.empty? || text.strip.empty?
      end

      def ==(other)
        other.is_a?(self.class) &&
          inline_runs == other.inline_runs &&
          style_id == other.style_id &&
          id == other.id &&
          footnote_refs == other.footnote_refs
      end
      alias eql? ==

      def hash
        [self.class, inline_runs, style_id, id, footnote_refs].hash
      end
    end
  end
end
