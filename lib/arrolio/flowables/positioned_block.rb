# frozen_string_literal: true

module Arrolio
  module Flowables
    # Absolute-positioned container for cover-page layouts. Renders
    # its children at a fixed (top, left) offset within the page,
    # regardless of the normal top-down flow.
    #
    # The engine treats PositionedBlock as zero-height in the flow
    # (consumed = 0), so the next flowable continues at the same
    # y-coordinate. The block's children are placed at page-relative
    # coordinates computed from +top+ and +left+.
    #
    # Used by cover layouts to place the title border-box, the
    # organisation footer block, and similar non-flow regions.
    class PositionedBlock < Flowable
      attr_reader :children, :top, :left, :width, :height_value

      # +children:+ Array of Flowable to render at the fixed position.
      # +top:+ Distance from the page's top edge (points).
      # +left:+ Distance from the page's left edge (points).
      # +width:+ Width of the block (points).
      # +height:+ Height of the block (points); content overflowing
      #   is clipped at render time.
      def initialize(children:, top:, left:, width:, height:,
                     style: Style::Definition.new)
        super(style: style)
        @children = Array(children)
        @top = top.to_f
        @left = left.to_f
        @width = width.to_f
        @height_value = height.to_f
      end

      def height(_width, _context = nil)
        0.0
      end

      def emit(x, y, _region_width, context = nil)
        page_top = y + (y).abs # approximate page-top from current y
        block_y = page_top - @top - @height_value
        block_x = x + @left
        boxes = []
        cursor = block_y + @height_value
        @children.each do |child|
          child_boxes, consumed = child.emit(block_x, cursor, @width, context)
          boxes.concat(child_boxes)
          cursor -= consumed
        end
        # The block consumes zero flow height — siblings continue at y.
        [boxes, 0.0]
      end
    end
  end
end
