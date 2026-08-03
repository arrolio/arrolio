# frozen_string_literal: true

module Arrolio
  module Content
    # Inline runs wrapped with a hyperlink target. The renderer
    # emits a PDF /Annot of subtype /Link with the URI (external)
    # or /Dest reference (internal cross-reference).
    class Hyperlink
      attr_reader :runs, :target, :id

      def initialize(runs, target:, internal: false, id: nil)
        @runs = Array(runs).freeze
        @target = target.to_s
        @internal_link = internal ? true : false
        @id = id&.to_s
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          runs == other.runs &&
          target == other.target &&
          internal? == other.internal? &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, runs, target, internal?, id].hash
      end

      def internal?
        @internal_link
      end

      def external?
        !internal?
      end
    end
  end
end
