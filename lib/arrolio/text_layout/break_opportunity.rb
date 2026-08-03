# frozen_string_literal: true

module Arrolio
  module TextLayout
    # A candidate line-break position within a list of InlineRuns.
    class BreakOpportunity
      attr_reader :run_index, :char_offset, :width_before, :type

      def initialize(run_index:, char_offset:, width_before:, type:)
        @run_index = run_index
        @char_offset = char_offset
        @width_before = width_before.to_f
        @type = type
        freeze
      end

      def forced?
        @type == :forced
      end

      def soft?
        @type == :soft
      end

      def ==(other)
        other.is_a?(self.class) &&
          run_index == other.run_index &&
          char_offset == other.char_offset &&
          width_before == other.width_before &&
          type == other.type
      end

      alias eql? ==

      def hash
        [self.class, run_index, char_offset, width_before, type].hash
      end

      class << self
        def each_in(runs, measurer:, font_size:)
          return enum_for(:each_in, runs, measurer: measurer, font_size: font_size) unless block_given?

          yield new(run_index: 0, char_offset: 0, width_before: 0.0, type: :start)

          cumulative = 0.0
          runs.each_with_index do |run, run_index|
            text = run.text
            i = 0
            while i < text.length
              ch = text[i]
              if ch == "\n"
                yield new(run_index: run_index, char_offset: i,
                          width_before: cumulative, type: :forced)
                i += 1
                next
              end

              if ch == ' '
                cumulative += char_width(run, ' ', measurer, font_size)
                yield new(run_index: run_index, char_offset: i + 1,
                          width_before: cumulative, type: :soft)
                i += 1
                next
              end

              if ch == '-' || ch == '—' || ch == '­'
                cumulative += char_width(run, ch, measurer, font_size)
                yield new(run_index: run_index, char_offset: i + 1,
                          width_before: cumulative, type: :soft)
                i += 1
                next
              end

              if ch == '​'
                yield new(run_index: run_index, char_offset: i,
                          width_before: cumulative, type: :soft)
                i += 1
                next
              end

              cumulative += char_width(run, ch, measurer, font_size)
              i += 1
            end
          end

          yield new(run_index: runs.length, char_offset: 0,
                    width_before: cumulative, type: :end)
        end

        private

        def char_width(run, char, measurer, font_size)
          measurer.width_of_run(
            char,
            font_size: font_size,
            character_spacing: run.style.character_spacing,
            word_spacing: 0
          )
        end
      end
    end
  end
end
