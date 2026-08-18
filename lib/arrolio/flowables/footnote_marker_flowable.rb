# frozen_string_literal: true

module Arrolio
  module Flowables
    # Anchors a footnote to the page it is referenced on and reserves
    # the vertical space its body needs at the page bottom.
    #
    # The footnote's layout policy lives here so the engine's height
    # accounting and the renderer's drawing agree by construction:
    # both ask `.body_flowable` for the same laid-out block. The
    # marker itself renders inline (superscript) from the paragraph's
    # run sequence; this flowable's job is space + page attribution.
    class FootnoteMarkerFlowable < Flowable
      attr_reader :footnote

      def initialize(footnote, style: Style::Definition.new(font_size: 9.0))
        super(style: style)
        @footnote = footnote
      end

      # The footnote as it renders at the page bottom: marker + ")"
      # prefix, body paragraphs joined, footnote style, 2pt gap after.
      def self.body_flowable(footnote, style)
        footnote_style = style.with(margin_top: 0.0, margin_bottom: 2.0)
        runs = [InlineRun.new("#{footnote.marker}) ", style: footnote_style)]
        footnote.body.each do |node|
          next unless node.is_a?(Content::Paragraph)

          node.inline_runs.each do |run|
            runs << InlineRun.new(run.text, style: footnote_style)
          end
        end
        TextFlowable.new(runs, style: footnote_style)
      end

      def height(width, _context = nil)
        self.class.body_flowable(@footnote, @style).height(width)
      end

      # Emits nothing into the body area - the consumed height frees
      # the bottom zone where the renderer draws the footnote body.
      def emit(_x, _y, width, _context = nil)
        [[], height(width)]
      end
    end
  end
end
