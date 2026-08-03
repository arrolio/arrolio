# frozen_string_literal: true

module Arrolio
  module TextLayout
    module KnuthPlass
      # Base class for items in the Knuth-Plass line-breaking model.
      # Every item has a width. Box and Glue are "content"; Penalty
      # is a potential break point.
      class Item
        attr_reader :width

        def initialize(width:)
          @width = width.to_f
        end

        def box? = false
        def glue? = false
        def penalty? = false
      end

      # A box is a unit of content that cannot be broken across
      # lines (a word, a glyph cluster). Has a fixed width.
      class Box < Item
        attr_reader :run_index, :char_offset, :char_length

        def initialize(width:, run_index:, char_offset:, char_length:)
          super(width: width)
          @run_index = run_index
          @char_offset = char_offset
          @char_length = char_length
        end

        def box? = true
      end

      # Glue represents inter-word space. Has a natural width plus
      # stretchability (how much it can grow) and shrinkability
      # (how much it can shrink). At a break point, trailing glue
      # is discarded (doesn't contribute to line width).
      class Glue < Item
        attr_reader :stretch, :shrink, :run_index, :char_offset

        def initialize(width:, stretch:, shrink:, run_index: nil, char_offset: nil)
          super(width: width)
          @stretch = stretch.to_f
          @shrink = shrink.to_f
          @run_index = run_index
          @char_offset = char_offset
        end

        def glue? = true
      end

      # A penalty represents a potential break point. Width is the
      # width of the hyphen (or 0 if no hyphen). Flagged penalties
      # (e.g., hyphenation) incur extra cost. A penalty of +Infinity+
      # means "never break here"; -Infinity means "always break".
      class Penalty < Item
        attr_reader :penalty, :flagged, :run_index, :char_offset

        def initialize(penalty:, width: 0, flagged: false, run_index: nil, char_offset: nil)
          super(width: width)
          @penalty = penalty.to_f
          @flagged = flagged
          @run_index = run_index
          @char_offset = char_offset
        end

        def penalty? = true

        def forced_break?
          @penalty == -Float::INFINITY
        end

        def no_break?
          @penalty == Float::INFINITY
        end
      end

      # A forced break at the end of a paragraph.
      FINISHED = Penalty.new(penalty: -Float::INFINITY).freeze
    end
  end
end
