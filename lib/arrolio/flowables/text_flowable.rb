# frozen_string_literal: true

module Arrolio
  module Flowables
    # A paragraph of flowing text. Selects a line-breaking strategy
    # based on the style's +line_break+ attribute (:greedy or
    # :knuth_plass). Both strategies produce TextLayout::Line[]
    # with the same shape, so the rest of the pipeline is agnostic.
    class TextFlowable < Flowable
      attr_reader :runs, :measurer

      def initialize(runs, style: Style::Definition.new, measurer: nil)
        super(style: style)
        @runs = Array(runs)
        @measurer = measurer || GlyphMeasurer.new(font_name: style.font_name)
      end

      def height(width, _context = nil)
        laid_out(width).length * line_height
      end

      def emit(x, y, width, _context = nil)
        lines = laid_out(width)
        return [[], 0.0] if lines.empty?

        box = Output::PlacedBox.text(
          x: x, y: y - (line_height * lines.length),
          width: width, height: line_height * lines.length,
          lines: lines, line_height: line_height, style: @style
        )
        [[box], box.height]
      end

      def splittable?
        true
      end

      def do_split(width, remaining_height, _context = nil)
        lines = laid_out(width)
        line_h = line_height
        head_count = (remaining_height.to_f / line_h).floor
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

      def collect_runs(lines)
        runs = []
        lines.each do |line|
          line.placed_runs.each { |pr| runs << pr.run }
        end
        runs
      end
    end
  end
end
