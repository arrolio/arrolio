# frozen_string_literal: true

module Arrolio
  module TextLayout
    module KnuthPlass
      # Optimal line breaking via dynamic programming (Knuth & Plass,
      # 1981). Finds the set of break points that minimizes the total
      # "badness" — the sum of squared adjustment ratios across all
      # lines, plus penalties for flagged breaks.
      #
      # The algorithm runs in O(n²) worst case (n = item count) but
      # converges in O(n) for typical text because most candidate
      # breaks are pruned early.
      #
      # Produces TextLayout::Line[] output — compatible with the
      # existing Greedy breaker so the engine can swap freely.
      class Breaker
        Infinity = Float::INFINITY

        # Tolerance for adjustment ratio — lines with ratio above
        # this are considered "underfull" and penalized.
        TOLERANCE = 100.0

        # Extra penalty for consecutive flagged breaks (hyphens).
        FLAGGED_PENALTY = 3000.0

        # Extra penalty for the last line being underfull.
        DEMERITS_LAST_LINE = 50.0

        attr_reader :items, :line_widths, :runs, :measurer, :align

        # +items:+ Array of KnuthPlass::Item (Box, Glue, Penalty).
        # +line_widths:+ Array of Float — width available per line.
        #   If shorter than the number of lines, the last width repeats.
        # +runs:+ Array of InlineRun — for building placed runs.
        # +measurer:+ GlyphMeasurer for width lookups.
        # +align:+ :left, :right, :center, :justify.
        def initialize(items:, line_widths:, runs:, measurer:, align: :left)
          @items = items
          @line_widths = line_widths
          @runs = runs
          @measurer = measurer
          @align = align
        end

        def layout
          nodes = active_nodes
          return [] if nodes.empty?

          # Only consider nodes that reached the end of the items
          # (the FINISHED penalty at the last position).
          final_nodes = nodes.select { |n| n.position == @items.length - 1 }
          return [] if final_nodes.empty?

          # Backtrack from the best final node.
          breaks = reconstruct_breaks(best_final_node(final_nodes))

          # Build Line objects from the break points.
          lines = []
          prev_item = 0
          breaks.each_with_index do |br, line_idx|
            width = line_width_for(line_idx)
            placed = build_placed_runs(prev_item, br, width)
            used = compute_line_width(prev_item, br)
            lines << Line.new(placed, width: used, max_width: width, align: @align)
            prev_item = br
          end
          lines
        end

        # Internal: a node in the dynamic programming graph.
        Node = Struct.new(:position, :line, :fitness, :total_demerits,
                          :previous, keyword_init: true)

        private

        # Active-node dynamic programming. Each active node represents
        # a feasible break position. We iterate through items and
        # try breaking at each feasible position.
        def active_nodes
          @active = [Node.new(position: -1, line: 0, fitness: 1,
                              total_demerits: 0, previous: nil)]
          @items.each_with_index do |_item, i|
            next unless feasible_break?(i)

            @active = @active.reject { |a| prune?(a, i) }
            candidates = @active.filter_map { |a| try_break(a, i) }
            best = best_candidate(candidates)
            @active << best if best
          end
          @active
        end

        def feasible_break?(i)
          item = @items[i]
          (item.penalty? && !item.no_break?) || (item.glue? && i.positive? && @items[i - 1].box?)
        end

        def prune?(node, _current)
          node.line >= @line_widths.length + 10
        end

        def try_break(node, break_pos)
          item = @items[break_pos]
          width = line_width_for(node.line)
          line_w = compute_line_width(node.position + 1, break_pos)

          is_forced = item.penalty? && item.forced_break?
          ratio = adjustment_ratio(line_w, width, break_pos)

          # Forced breaks are always accepted but still penalized
          # for bad ratios so the algorithm prefers shorter lines.
          unless is_forced
            return nil if ratio.abs > TOLERANCE
          end

          ratio = 0.0 if ratio == Infinity || ratio == -Infinity
          demerits = demerits_for(ratio, break_pos)
          total = node.total_demerits + demerits
          fitness = fitness_class(ratio)

          Node.new(
            position: break_pos,
            line: node.line + 1,
            fitness: fitness,
            total_demerits: total,
            previous: node
          )
        end

        def best_candidate(candidates)
          candidates.min_by(&:total_demerits)
        end

        def best_final_node(nodes)
          nodes.min_by(&:total_demerits)
        end

        # Adjustment ratio: how stretched (positive) or shrunk
        # (negative) a line is. 0 = perfect fit.
        def adjustment_ratio(natural_width, target_width, break_pos)
          glue_stretch = total_stretch(break_pos)
          glue_shrink = total_shrink(break_pos)

          if natural_width < target_width
            glue_stretch.positive? ? (target_width - natural_width) / glue_stretch : Infinity
          elsif natural_width > target_width
            glue_shrink.positive? ? (target_width - natural_width) / glue_shrink : -Infinity
          else
            0.0
          end
        end

        def demerits_for(ratio, break_pos)
          penalty = @items[break_pos].penalty? ? @items[break_pos].penalty : 0
          badness = if ratio.negative?
            (100 * ((-ratio) ** 3)).to_i
          else
            0
                    end
          # Standard Knuth-Plass demerits. Forced breaks (penalty =
          # -Infinity) use d = (1 + badness)^2 — the penalty term
          # drops out because there's no choice about breaking.
          d = if penalty.infinite?
                (1 + badness) ** 2
              elsif penalty >= 0
                (1 + badness + penalty) ** 2
              else
                ((1 + badness) ** 2) - (penalty ** 2)
              end
          flagged = @items[break_pos].penalty? && @items[break_pos].flagged ? FLAGGED_PENALTY : 0
          d + flagged
        end

        def fitness_class(ratio)
          case ratio
          when -Infinity..-0.5 then 0 # tight
          when -0.5..0.5 then 1       # normal
          when 0.5..1.0 then 2        # loose
          else 3                       # very loose
          end
        end

        # Sum of widths from item +start+ to item +stop+ (exclusive).
        # Discards trailing glue at the break point.
        def compute_line_width(start, stop)
          return 0.0 if start >= stop

          sum = 0.0
          (start...stop).each do |i|
            item = @items[i]
            next if item.nil?

            # Trailing glue after last box is discarded at break.
            last_box = last_box_index_in(start, stop)
            sum += item.width if i <= last_box
          end
          sum
        end

        def last_box_index_in(start, stop)
          idx = start - 1
          (start...stop).each do |i|
            idx = i if @items[i]&.box?
          end
          idx
        end

        def total_stretch(break_pos)
          sum = 0.0
          @items[0..break_pos].each { |item| sum += item.stretch if item.glue? }
          sum
        end

        def total_shrink(break_pos)
          sum = 0.0
          @items[0..break_pos].each { |item| sum += item.shrink if item.glue? }
          sum
        end

        def line_width_for(line_idx)
          @line_widths[[line_idx, @line_widths.length - 1].min]
        end

        def reconstruct_breaks(final_node)
          breaks = []
          node = final_node
          while node&.previous
            breaks << node.position
            node = node.previous
          end
          breaks.reverse
        end

        def build_placed_runs(start_item, stop_item, _width)
          placed = []
          x_offset = 0.0
          (start_item...stop_item).each do |i|
            item = @items[i]
            next unless item&.box?

            run = @runs[item.run_index]
            next unless run

            slice = run.text[item.char_offset, item.char_length]
            next if slice.nil? || slice.empty?

            sub = InlineRun.new(slice, style: run.style,
                                       baseline_shift: run.baseline_shift,
                                       font_size_scale: run.font_size_scale,
                                       href: run.href)
            placed << Line::PlacedRun.new(run: sub, x_offset: x_offset)
            x_offset += item.width
          end
          placed
        end

        def finalize_node(position, line, fitness, total_demerits, previous)
          Node.new(position: position, line: line, fitness: fitness,
                   total_demerits: total_demerits, previous: previous)
        end
      end
    end
  end
end
