# frozen_string_literal: true

module Arrolio
  module Flowables
    # Zero-height placeholder that signals "the footnote with this id
    # appears on the current page". The engine detects these during
    # layout and records the footnote on the current Output::Page so
    # the renderer can draw it at the bottom of the page.
    #
    # Carries a reference to the full Content::Footnote (marker +
    # body). The marker is also rendered inline (as a superscript
    # indicator) by the flow builder when it constructs the run
    # sequence; this flowable's sole job is to anchor the footnote
    # to a page.
    class FootnoteMarkerFlowable < Flowable
      attr_reader :footnote

      def initialize(footnote)
        super(style: Style::Definition.new)
        @footnote = footnote
      end

      def height(_width, _context = nil) = 0.0

      def emit(_x, _y, _width, _context = nil) = [[], 0.0]
    end
  end
end
