# frozen_string_literal: true

# Arrolio::Flowable — abstract base for everything the page-flow
# engine places into Frames.
module Arrolio
  class Flowable
    attr_reader :style

    def initialize(style: Style::Definition.new)
      @style = style
    end

    def height(_width, _context = nil)
      raise NotImplementedError, "#{self.class}#height not implemented"
    end

    def emit(_x, _y, _width, _context = nil)
      raise NotImplementedError, "#{self.class}#emit not implemented"
    end

    def splittable?
      false
    end

    def keep_together?
      @style.keep_together
    end

    def keep_with_next?
      @style.keep_with_next
    end

    # Height that must stay on the same page as a preceding
    # keep-with-next flowable: the whole flowable when atomic, the
    # first line (plus space-before) when splittable.
    def min_keep_height(width, context = nil)
      height(width, context)
    end

    def page_break_before?
      @style.page_break_before
    end

    def page_break_after?
      @style.page_break_after
    end

    def space_before
      @style.margin_top
    end

    def space_after
      @style.margin_bottom
    end

    def split(width, remaining_height, context = nil)
      natural = height(width, context)
      if natural <= remaining_height
        [self, nil]
      elsif splittable?
        do_split(width, remaining_height, context)
      elsif keep_together?
        [nil, self]
      else
        [self, nil]
      end
    end

    def do_split(_width, _remaining_height, _context = nil)
      [self, nil]
    end
  end
end
