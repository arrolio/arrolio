# frozen_string_literal: true

module Arrolio
  module Flowables
    # A paragraph of flowing text. Selects a line-breaking strategy
    # based on the style's +line_break+ attribute (:greedy or
    # :knuth_plass). Both strategies produce TextLayout::Line[]
    # with the same shape, so the rest of the pipeline is agnostic.
    class TextFlowable < Flowable
      attr_reader :runs, :measurer, :hanging_indent

      def initialize(runs, style: Style::Definition.new, measurer: nil,
                     hanging_indent: 0.0)
        super(style: style)
        @runs = Array(runs)
        @measurer = measurer || GlyphMeasurer.new(font_name: style.font_name)
        @hanging_indent = hanging_indent.to_f
      end

      def height(width, _context = nil)
        effective_width = width - @hanging_indent
        (laid_out(effective_width).length * line_height) + space_before + space_after
      end

      def emit(x, y, width, _context = nil)
        effective_width = width - @hanging_indent
        lines = laid_out(effective_width)
        text_height = line_height * lines.length
        total = text_height + space_before + space_after
        return [[], total] if lines.empty?

        text_y = y - space_before
        box = Output::PlacedBox.text(
          x: x, y: text_y - text_height,
          width: width, height: text_height,
          lines: lines, line_height: line_height, style: @style,
          hanging_indent: @hanging_indent
        )
        [[box], total]
      end

      def splittable?
        true
      end

      def do_split(width, remaining_height, _context = nil)
        lines = laid_out(width)
        line_h = line_height
        available = remaining_height - space_before
        head_count = (available.to_f / line_h).floor
        head_count = [head_count, lines.length].min
        head_count = 1 if head_count < 1 && lines.any?

        head_lines = lines[0...head_count]
        tail_lines = lines[head_count..] || []

        head_runs = collect_runs(head_lines)
        tail_runs = collect_runs(tail_lines)

        head = head_runs.empty? ? nil : self.class.new(head_runs, style: @style, measurer: @measurer)
        tail = tail_runs.empty? ? nil : self.class.new(tail_runs, style: @style, measurer: @measurer)
        [head, tail]
      end

      private

      def laid_out(width)
        case @style.line_break
        when :knuth_plass
          layout_knuth_plass(width)
        else
          layout_greedy(width)
        end
      end

      def layout_greedy(width)
        TextLayout::Greedy.new(@runs, measurer: @measurer,
                                      width: width,
                                      align: @style.align).layout
      end

      def layout_knuth_plass(width)
        items = TextLayout::KnuthPlass::ItemBuilder.new(@runs, measurer: @measurer).build
        TextLayout::KnuthPlass::Breaker.new(
          items: items, line_widths: [width], runs: @runs,
          measurer: @measurer, align: @style.align
        ).layout
      end

      def line_height
        @measurer.line_height(font_size: @style.font_size,
                              line_spacing: @style.line_spacing)
      end

      # Rebuilds a run list from laid-out lines. A line break
      # consumes the inter-word glue, and placed runs don't carry it,
      # so a separator is re-inserted at each line boundary —
      # otherwise re-layout glues the boundary words together
      # ("…increasing and" + "decreasing loads."). Hyphen breaks
      # already join their words; they must not gain a space.
      def collect_runs(lines)
        runs = []
        lines.each do |line|
          first = line.placed_runs.first&.run
          runs << InlineRun.new(' ', style: first.style) if separator_needed?(runs.last, first)
          line.placed_runs.each { |pr| runs << pr.run }
        end
        runs
      end

      def separator_needed?(last_run, first_run)
        return false if last_run.nil? || first_run.nil?
        return false if last_run.text.end_with?('-')
        return false if last_run.text.match?(/\s\z/) || first_run.text.match?(/\A\s/)

        true
      end
    end
  end
end
