# frozen_string_literal: true

module Arrolio
  module Content
    # An explicit page break in the content tree. Emitted by the
    # adapter when it encounters a <pagebreak/> element or a clause
    # with a page-break-before hint. The FlowBuilder converts this
    # to a Flowables::PageBreak.
    class PageBreak
      attr_reader :id

      def initialize(id: nil)
        @id = id&.to_s
        freeze
      end

      def ==(other)
        other.is_a?(self.class) && id == other.id
      end

      alias eql? ==

      def hash
        [self.class, id].hash
      end
    end
  end
end
