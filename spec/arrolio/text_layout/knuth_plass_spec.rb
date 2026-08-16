# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::TextLayout::KnuthPlass do
  describe Arrolio::TextLayout::KnuthPlass::Item do
    describe Arrolio::TextLayout::KnuthPlass::Box do
      it 'is a box' do
        box = described_class.new(width: 50, run_index: 0, char_offset: 0, char_length: 5)
        expect(box).to be_box
        expect(box.width).to eq(50.0)
      end
    end

    describe Arrolio::TextLayout::KnuthPlass::Glue do
      it 'has stretch and shrink' do
        glue = described_class.new(width: 10, stretch: 5, shrink: 3)
        expect(glue).to be_glue
        expect(glue.stretch).to eq(5.0)
        expect(glue.shrink).to eq(3.0)
      end
    end

    describe Arrolio::TextLayout::KnuthPlass::Penalty do
      it 'detects forced breaks' do
        p = described_class.new(penalty: -Float::INFINITY)
        expect(p).to be_forced_break
        expect(p).not_to be_no_break
      end

      it 'detects no-break' do
        p = described_class.new(penalty: Float::INFINITY)
        expect(p).to be_no_break
        expect(p).not_to be_forced_break
      end
    end
  end

  describe Arrolio::TextLayout::KnuthPlass::ItemBuilder do
    let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12) }
    let(:runs) { [Arrolio::InlineRun.new('hello world foo', style: style)] }
    let(:measurer) do
      Struct.new(:calls, keyword_init: true) do
        def width_of_run(text, font_size:, **_)
          text.length * font_size * 0.5
        end
      end.new(calls: [])
    end

    it 'produces boxes and glue from text' do
      items = described_class.new(runs, measurer: measurer).build
      boxes = items.count(&:box?)
      glues = items.count(&:glue?)
      expect(boxes).to eq(3) # three words
      expect(glues).to eq(3) # two spaces + one emergency-stretch glue
    end

    it 'appends FINISHED at the end' do
      items = described_class.new(runs, measurer: measurer).build
      expect(items.last).to be_forced_break
    end
  end

  describe Arrolio::TextLayout::KnuthPlass::Breaker do
    let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12) }
    let(:measurer) do
      Struct.new(:dummy, keyword_init: true) do
        def width_of_run(text, font_size:, **_)
          text.length * font_size * 0.5
        end
      end.new(dummy: nil)
    end

    def layout(text, width, runs = nil)
      runs ||= [Arrolio::InlineRun.new(text, style: style)]
      items = Arrolio::TextLayout::KnuthPlass::ItemBuilder.new(runs, measurer: measurer).build
      described_class.new(
        items: items, line_widths: [width], runs: runs,
        measurer: measurer, align: :left
      ).layout
    end

    it 'lays out text that fits on one line as one line' do
      lines = layout('short', 500.0)
      expect(lines.length).to eq(1)
    end

    it 'wraps long text into multiple lines' do
      lines = layout('word ' * 20, 100.0)
      expect(lines.length).to be > 1
    end

    it 'never returns a line wider than the measure' do
      lines = layout('word ' * 20, 100.0)
      expect(lines.all? { |l| l.width <= 100.0 }).to be(true)
    end

    # Every intermediate break is looser than TOLERANCE, so the first
    # pass finds no feasible split. Without the emergency-stretch
    # pass the only surviving path is the forced final break and the
    # whole paragraph renders as one overfull, off-page line.
    it 'breaks paragraphs with no feasible split via emergency stretch' do
      lines = layout('aaaa bbbb cccc dddd', 70.0)
      expect(lines.length).to eq(2)
      expect(lines.all? { |l| l.width <= 70.0 }).to be(true)
      expect(lines.map { |l| l.placed_runs.map { |pr| pr.run.text }.join }.join(' '))
        .to eq('aaaa bbbb cccc dddd')
    end

    it 'lays out paragraphs longer than eleven lines' do
      lines = layout('word ' * 24, 75.0)
      expect(lines.length).to eq(12)
      expect(lines.all? { |l| l.width <= 75.0 }).to be(true)
    end

    it 'keeps mixed-style runs as separate placed runs' do
      bold = style.with(font_name: 'Times-Bold')
      runs = [
        Arrolio::InlineRun.new('one ', style: style),
        Arrolio::InlineRun.new('two', style: bold),
        Arrolio::InlineRun.new(' three', style: style)
      ]
      lines = layout('one two three', 500.0, runs)
      expect(lines.length).to eq(1)
      fonts = lines.first.placed_runs.map { |pr| pr.run.style.font_name }
      expect(fonts).to eq(['Times-Roman', 'Times-Bold', 'Times-Roman'])
      expect(lines.first.placed_runs.map { |pr| pr.run.text }).to eq(['one ', 'two ', 'three'])
    end

    it 'drops the trailing glue so justify counts real gaps only' do
      lines = layout('one two three', 500.0)
      expect(lines.first.placed_runs.map { |pr| pr.run.text }.join).to eq('one two three')
    end
  end
end
