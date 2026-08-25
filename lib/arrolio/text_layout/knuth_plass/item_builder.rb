# frozen_string_literal: true

module Arrolio
  module TextLayout
    module KnuthPlass
      # Converts a list of InlineRun values into KnuthPlass::Item
      # sequences (Box, Glue, Penalty). Each word becomes a Box;
      # spaces become Glue; potential break points become Penalty
      # items.
      class ItemBuilder
        HYPHEN_PENALTY = 50.0

        attr_reader :runs, :measurer

        def initialize(runs, measurer:)
          @runs = runs
          @measurer = measurer
        end

        def build
          items = []
          @runs.each_with_index do |run, run_idx|
            build_items_for_run(run, run_idx, items)
          end
          # Parfillskip: zero-width glue with infinite stretch before
          # the FINISHED penalty (TeX's \parfillskip). Makes the last
          # line of a paragraph never loose, so short final lines are
          # always feasible. Paragraphs with no feasible intermediate
          # break are rescued by Breaker's emergency-stretch pass.
          items << Glue.new(width: 0, stretch: Float::INFINITY, shrink: 0)
          items << FINISHED
          items
        end

        private

        def build_items_for_run(run, run_idx, items)
          text = run.text
          return if text.nil? || text.empty?

          # Handle forced breaks first.
          if text.include?("\n")
            build_newline_items(run, run_idx, text, items)
            return
          end

          build_word_items(run, run_idx, text, 0, items)
        end

        # A run with embedded newlines wraps WITHIN each segment
        # (a segment can be a whole paragraph) and places a forced
        # break between segments. Emitting each segment as a single
        # box made long segments unbreakable overfull lines.
        def build_newline_items(run, run_idx, text, items)
          # -1 keeps trailing empty segments: a lone "\n" run
          # must still emit its forced-break penalty.
          segments = text.split("\n", -1)
          base = 0
          segments.each_with_index do |seg, i|
            build_word_items(run, run_idx, seg, base, items) unless seg.empty?
            base += seg.length + 1
            items << Penalty.new(penalty: -Float::INFINITY, run_index: run_idx) if i < segments.length - 1
          end
        end

        def build_word_items(run, run_idx, text, base_offset, items)
          words = text.split(/(\s+)/)
          offset = 0
          words.each do |word|
            if word.match?(/\s+/)
              width = measure(word, run)
              stretch = measure(' ', run) * 0.5
              shrink = measure(' ', run) * 0.33
              items << Glue.new(width: width, stretch: stretch, shrink: shrink,
                                run_index: run_idx, char_offset: base_offset + offset)
            elsif word.include?('-')
              build_hyphenated_word(word, run, run_idx, base_offset + offset, items)
            elsif !word.empty?
              width = measure(word, run)
              items << Box.new(width: width, run_index: run_idx,
                               char_offset: base_offset + offset, char_length: word.length)
            end
            offset += word.length
          end
        end

        def build_hyphenated_word(word, run, run_idx, offset, items)
          parts = word.split(/(-)/)
          part_offset = offset
          parts.each do |part|
            next if part.empty?

            width = measure(part, run)
            items << Box.new(width: width, run_index: run_idx,
                             char_offset: part_offset, char_length: part.length)
            if part == '-'
              items << Penalty.new(width: 0, penalty: HYPHEN_PENALTY,
                                   flagged: true, run_index: run_idx,
                                   char_offset: part_offset)
            end
            part_offset += part.length
          end
        end

        def measure(text, run)
          @measurer.width_of_run(
            text,
            font_size: run.style.font_size * run.font_size_scale,
            character_spacing: run.style.character_spacing,
            word_spacing: 0
          )
        end
      end
    end
  end
end
