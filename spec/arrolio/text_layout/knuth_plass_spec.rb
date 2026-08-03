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
      expect(glues).to eq(2) # two spaces
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

    it 'lays out text that fits on one line as one line' do
      run = Arrolio::InlineRun.new('short', style: style)
      items = Arrolio::TextLayout::KnuthPlass::ItemBuilder.new([run], measurer: measurer).build
      breaker = described_class.new(
        items: items, line_widths: [500.0], runs: [run],
        measurer: measurer, align: :left
      )
      lines = breaker.layout
      expect(lines.length).to eq(1)
    end

    it 'wraps long text into multiple lines' do
      run = Arrolio::InlineRun.new('word ' * 20, style: style)
      items = Arrolio::TextLayout::KnuthPlass::ItemBuilder.new([run], measurer: measurer).build
      breaker = described_class.new(
        items: items, line_widths: [100.0], runs: [run],
        measurer: measurer, align: :left
      )
      lines = breaker.layout
      expect(lines.length).to be > 1
    end
  end
end
