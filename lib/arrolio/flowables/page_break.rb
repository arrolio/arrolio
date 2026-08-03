# frozen_string_literal: true

module Arrolio
  module Flowables
    class PageBreak < Flowable
      def height(_width, _context = nil) = 0.0

      def emit(_x, _y, _width, _context = nil) = [[], 0.0]

      def page_break_after?
        true
      end
    end
  end
end
