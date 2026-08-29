# frozen_string_literal: true

module Arrolio
  module TextLayout
    # First-fit greedy line breaker. FOP's default. Linear time.
    class Greedy
      attr_reader :runs, :measurer, :width, :align

      def initialize(runs, measurer:, width:, align: :left)
        @runs = runs
        @measurer = measurer
        @width = width.to_f
        @align = align
      end

      def layout
        opps = opportunities
        return [] if opps.empty? || opps.length == 1

        lines = []
        line_start = 0
        i = 1
        while i < opps.length
          opp = opps[i]
          prev = opps[i - 1]

          if opp.forced?
            emit_line(lines, opps, line_start, i, prev.width_before)
            line_start = i + 1
            i += 2
            next
          end

          if overflows?(opps, line_start, opp) && (i - line_start > 1)
            emit_line(lines, opps, line_start, i - 1, prev.width_before)
            line_start = i - 1
          end
          i += 1
        end

        emit_final_line(lines, opps, line_start) unless lines_built_complete?(opps, line_start)
        lines
      end

      private

      def opportunities
        BreakOpportunity.each_in(@runs, measurer: @measurer,
                                        font_size: font_size).to_a
      end

      def font_size
        @runs.first&.style&.font_size || 12
      end

      def overflows?(opps, line_start, opp)
        opp.width_before - opps[line_start].width_before > @width
      end

      def emit_line(lines, opps, start_idx, end_idx, _line_width)
        placed = build_placed_runs(opps, start_idx, end_idx)
        width_used = opps[end_idx].width_before - opps[start_idx].width_before
        lines << Line.new(placed, width: width_used,
                                  max_width: @width, align: @align)
      end

      def emit_final_line(lines, opps, line_start)
        last = opps.last
        prev_w = line_start.positive? ? opps[line_start - 1].width_before : 0.0
        return if last.width_before <= prev_w && !lines.empty?

        emit_line(lines, opps, line_start, opps.length - 1, last.width_before)
      end

      def lines_built_complete?(opps, line_start)
        line_start >= opps.length - 1
      end

      def build_placed_runs(opps, start_idx, end_idx)
        return [] if start_idx >= end_idx

        start_opp = opps[start_idx]
        end_opp = opps[end_idx] || opps.last
        start_run = start_opp.run_index
        start_off = start_opp.char_offset
        end_run = end_opp.run_index
        end_off = end_opp.char_offset

        placed = []
        x_offset = 0.0
        (start_run..end_run).each do |run_idx|
          next unless run_idx < @runs.length

          run = @runs[run_idx]
          s_off = run_idx == start_run ? start_off : 0
          e_off = run_idx == end_run ? end_off : run.text.length
          next if s_off >= e_off

          slice = run.text[s_off, e_off - s_off]
          next if slice.nil? || slice.empty?

          sub_run = InlineRun.new(slice, style: run.style)
          placed << Line::PlacedRun.new(run: sub_run, x_offset: x_offset,
                                        chunk_widths: chunk_widths(run, slice))
          x_offset += sub_run.width(@measurer)
        end
        placed
      end

      # Width of each emission chunk (text split after
      # whitespace) — the same chunking the renderer uses. The
      # breaker owns measurement; the renderer advances by these.
      def chunk_widths(run, slice)
        font = run.style.font_name
        size = run.style.font_size * run.font_size_scale
        slice.split(/(?<=\s)(?=\S)/).map do |chunk|
          @measurer.width_of_run(chunk, font_size: size,
                                        character_spacing: run.style.character_spacing,
                                        word_spacing: 0, font_name: font)
        end
      end
    end
  end
end
