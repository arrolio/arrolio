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
      # When no break sequence is feasible within TOLERANCE (every
      # candidate line is too loose), a second pass runs with
      # emergency stretch added to every line's stretchability —
      # TeX's \emergencystretch. Without it, the only surviving path
      # is the forced final break, which packs the whole paragraph
      # into one overfull line and silently runs off the page.
      #
      # Produces TextLayout::Line[] output — compatible with the
      # existing Greedy breaker so the engine can swap freely.
      class Breaker
        Infinity = Float::INFINITY

        # Tolerance for adjustment ratio — lines with |ratio| above
        # this are infeasible and rejected. Standard TeX default
        # (\tolerance=200) maps to ratio ≈ 1.26 because badness is
        # 100*|r|^3. We use a slightly looser limit (2.5) to allow
        # reasonable stretch on tight paragraphs while rejecting
        # the pathological overfills greedy avoids by construction.
        TOLERANCE = 2.5

        # Stretch added to every line during the emergency pass.
        # Comparable to TeX's \emergencystretch = 2em at body size.
        EMERGENCY_STRETCH = 20.0

        # Extra penalty for consecutive flagged breaks (hyphens).
        FLAGGED_PENALTY = 3000.0

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
          build_prefix_sums
          node = solve
          node = solve(emergency_stretch: EMERGENCY_STRETCH) unless feasible?(node)
          return [] if node.nil?

          build_lines(node)
        end

        # Internal: a node in the dynamic programming graph.
        Node = Struct.new(:position, :line, :fitness, :total_demerits,
                          :previous, keyword_init: true)

        # Internal: a run of same-signature text being merged into a
        # single PlacedRun (one canvas.text call at render time).
        RunGroup = Struct.new(:signature, :text, :x_offset, keyword_init: true)

        private

        # Active-node dynamic programming. Each active node represents
        # a feasible break position. We iterate through items and
        # try breaking at each feasible position.
        def solve(emergency_stretch: 0.0)
          @emergency_stretch = emergency_stretch.to_f
          active = [Node.new(position: -1, line: 0, fitness: 1,
                             total_demerits: 0, previous: nil)]
          @items.each_with_index do |item, i|
            next unless feasible_break?(i)

            best = best_candidate(active.filter_map { |a| try_break(a, i) })
            next unless best

            if item.penalty? && item.forced_break?
              # A forced break must be taken: no earlier active node
              # may span across it (otherwise the DP happily skips
              # forced breaks when the parfill glue makes the single
              # line feasible).
              active = [best]
            else
              active << best
            end
          end
          best_final_node(active.select { |n| n.position == @items.length - 1 })
        end

        # True when the solution contains no line whose adjustment
        # ratio escaped TOLERANCE via a forced break. When false, the
        # paragraph needs the emergency pass.
        def feasible?(final_node)
          return false if final_node.nil?

          prev_item = 0
          reconstruct_breaks(final_node).each_with_index do |br, line_idx|
            natural = compute_line_width(prev_item, br)
            ratio = adjustment_ratio(natural, line_width_for(line_idx),
                                     prev_item, br)
            return false if ratio.abs > TOLERANCE

            prev_item = br
          end
          true
        end

        def build_lines(final_node)
          lines = []
          prev_item = 0
          reconstruct_breaks(final_node).each_with_index do |br, line_idx|
            width = line_width_for(line_idx)
            placed = build_placed_runs(prev_item, br)
            lines << Line.new(placed, width: compute_line_width(prev_item, br),
                                      max_width: width, align: @align)
            prev_item = br
          end
          lines
        end

        def feasible_break?(i)
          item = @items[i]
          (item.penalty? && !item.no_break?) || (item.glue? && i.positive? && @items[i - 1].box?)
        end

        def try_break(node, break_pos)
          item = @items[break_pos]
          width = line_width_for(node.line)
          line_start = node.position + 1
          line_w = compute_line_width(line_start, break_pos)

          is_forced = item.penalty? && item.forced_break?
          ratio = adjustment_ratio(line_w, width, line_start, break_pos)

          # Forced breaks are always accepted but still penalized
          # for bad ratios so the algorithm prefers shorter lines.
          return nil if !is_forced && ratio.abs > TOLERANCE

          ratio = 0.0 if ratio.infinite?
          demerits = demerits_for(ratio, break_pos)
          total = node.total_demerits + demerits

          Node.new(
            position: break_pos,
            line: node.line + 1,
            fitness: fitness_class(ratio),
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
        # (negative) a line is. 0 = perfect fit. Emergency stretch
        # widens the feasibility window without changing shrink.
        def adjustment_ratio(natural_width, target_width, line_start, line_end)
          glue_stretch = line_stretch(line_start, line_end) + @emergency_stretch
          glue_shrink = line_shrink(line_start, line_end)

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
          badness = (100 * (ratio.abs ** 3)).clamp(0, 10_000).to_i
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

        # Prefix sums so range width/stretch/shrink queries are O(1).
        def build_prefix_sums
          @prefix_width = [0.0]
          @prefix_stretch = [0.0]
          @prefix_shrink = [0.0]
          @items.each do |item|
            @prefix_width << (@prefix_width.last + item.width.to_f)
            @prefix_stretch << (@prefix_stretch.last + (item.glue? ? item.stretch : 0.0))
            @prefix_shrink << (@prefix_shrink.last + (item.glue? ? item.shrink : 0.0))
          end
        end

        # Sum of widths from item +start+ to item +stop+ (exclusive).
        # Discards trailing glue at the break point.
        def compute_line_width(start, stop)
          return 0.0 if start >= stop

          last_box = last_box_index_in(start, stop)
          last_box < start ? 0.0 : @prefix_width[last_box + 1] - @prefix_width[start]
        end

        def last_box_index_in(start, stop)
          idx = start - 1
          (start...stop).each do |i|
            idx = i if @items[i]&.box?
          end
          idx
        end

        def line_stretch(line_start, line_end)
          @prefix_stretch[line_end] - @prefix_stretch[line_start]
        end

        def line_shrink(line_start, line_end)
          @prefix_shrink[line_end] - @prefix_shrink[line_start]
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

        # Merges contiguous Box + Glue items into PlacedRuns — one
        # canvas.text call per group — so pdftotext sees word
        # separators instead of glued-together Tj fragments. A new
        # group starts whenever the rendering signature (style,
        # baseline shift, scale, href) changes, so bold/italic and
        # sub/superscript runs keep their formatting. Glue past the
        # line's last box (at the break) is dropped: it is discarded
        # by width accounting and would otherwise inflate the
        # renderer's justify word count.
        def build_placed_runs(start_item, stop_item)
          last_box = last_box_index_in(start_item, stop_item)
          placed = []
          group = nil

          (start_item...stop_item).each do |i|
            item = @items[i]
            next unless item
            next if item.glue? && item.stretch.infinite?

            if item.box?
              run = @runs[item.run_index]
              next unless run

              slice = run.text[item.char_offset, item.char_length]
              next if slice.nil? || slice.empty?

              signature = [run.style, run.baseline_shift,
                           run.font_size_scale, run.href]
              if group.nil? || group.signature != signature
                flush_placed_group(placed, group) if group
                group = RunGroup.new(signature: signature, text: String.new,
                                     x_offset: item_offset(start_item, i))
              end
              group.text << slice
            elsif item.glue? && group && i < last_box
              group.text << ' '
            end
          end
          flush_placed_group(placed, group) if group
          placed
        end

        def item_offset(start_item, item_idx)
          @prefix_width[item_idx] - @prefix_width[start_item]
        end

        def flush_placed_group(placed, group)
          return if group.text.empty?

          style, baseline_shift, font_size_scale, href = group.signature
          run = InlineRun.new(group.text, style: style,
                                          baseline_shift: baseline_shift,
                                          font_size_scale: font_size_scale,
                                          href: href)
          placed << Line::PlacedRun.new(run: run, x_offset: group.x_offset)
        end
      end
    end
  end
end
