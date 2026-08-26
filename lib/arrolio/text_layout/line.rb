# frozen_string_literal: true

module Arrolio
  module TextLayout
    # One laid-out line: a list of PlacedRun tuples plus the
    # line's content width, target width, and alignment.
    class Line
      PlacedRun = Struct.new(:run, :x_offset, keyword_init: true) do
        def freeze
          run.freeze
          super
        end
      end

      attr_reader :placed_runs, :width, :max_width, :align

      def initialize(placed_runs, width:, max_width:, align: :left)
        @placed_runs = placed_runs.freeze
        @width = width.to_f
        @max_width = max_width.to_f
        @align = align
        freeze
      end

      def empty?
        @placed_runs.empty?
      end

      def x_offset
        case @align
        when :center then ((@max_width - @width) / 2.0)
        when :right then (@max_width - @width)
        else 0.0
        end
      end

      def justified?
        @align == :justify
      end

      # Negative when the line is overfull (TeX shrink): the
      # renderer compresses inter-word gaps. Clamping at zero made
      # compressed lines draw at natural width, past the measure.
      def justify_stretch
        return 0.0 unless justified?

        gaps = word_gap_count
        return 0.0 if gaps.zero?

        (@max_width - @width) / gaps.to_f
      end

      def ==(other)
        other.is_a?(self.class) &&
          placed_runs == other.placed_runs &&
          width == other.width &&
          max_width == other.max_width &&
          align == other.align
      end

      alias eql? ==

      def hash
        [self.class, placed_runs, width, max_width, align].hash
      end

      private

      def word_gap_count
        @placed_runs.sum { |pr| pr.run.text.count(' ') }
      end
    end
  end
end
