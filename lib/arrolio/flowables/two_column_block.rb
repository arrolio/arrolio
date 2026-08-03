# frozen_string_literal: true

module Arrolio
  module Flowables
    # Two-column layout for a cover-page header. Renders left and right
    # content blocks side-by-side without table borders, matching the
    # reference PDF's two-column fo:table layout. Used by flow builders
    # to place flavor-specific cover text in two columns.
    class TwoColumnBlock < Flowable
      attr_reader :left_flowables, :right_flowables, :left_ratio, :style

      # +left_flowables:+ Array of TextFlowable for the left column.
      # +right_flowables:+ Array of TextFlowable for the right column.
      # +left_ratio:+ Fraction of width for the left column (default 0.5).
      def initialize(left_flowables:, right_flowables:, left_ratio: 0.5,
                     style: Style::Definition.new)
        super(style: style)
        @left_flowables = Array(left_flowables)
        @right_flowables = Array(right_flowables)
        @left_ratio = left_ratio.to_f
      end

      def height(width, context = nil)
        left_w = width * @left_ratio
        right_w = width * (1.0 - @left_ratio)
        left_h = @left_flowables.sum { |f| f.height(left_w, context) }
        right_h = @right_flowables.sum { |f| f.height(right_w, context) }
        [left_h, right_h].max
      end

      def emit(x, y, width, context = nil)
        left_w = width * @left_ratio
        right_w = width * (1.0 - @left_ratio)
        right_x = x + left_w
        boxes = []

        left_cursor = y
        @left_flowables.each do |f|
          fboxes, consumed = f.emit(x, left_cursor, left_w, context)
          boxes.concat(fboxes)
          left_cursor -= consumed
        end

        right_cursor = y
        @right_flowables.each do |f|
          fboxes, consumed = f.emit(right_x, right_cursor, right_w, context)
          boxes.concat(fboxes)
          right_cursor -= consumed
        end

        consumed = [y - left_cursor, y - right_cursor].max
        [boxes, consumed]
      end
    end
  end
end
