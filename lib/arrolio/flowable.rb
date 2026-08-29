# frozen_string_literal: true

# Arrolio::Flowable — abstract base for everything the page-flow
# engine places into Frames.
#
# Margin contract: +space_before+/+space_after+ expose the style's
# margins. The ENGINE collapses min(prev.space_after,
# curr.space_before) into the gap and adds it above the flowable's
# emit origin. Two conventions coexist and must not be mixed:
#
# - TextFlowable counts its margins INSIDE height/emit (consumed
#   includes before+after; the engine subtracts the overlap).
# - ListFlowable and its subclasses (lists, notes) do NOT count
#   margins in height — spacing around them comes from explicit
#   Spacers (see GenericFlowBuilder's term notes).
#
# A flowable's height() and emit() must agree on whether margins
# are included, or fit checks and drawing diverge.
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
