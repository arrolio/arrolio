# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TextFlowable do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 12) }
  let(:measurer) do
    Struct.new(:dummy, keyword_init: true) do
      def width_of_run(text, font_size:, **_)
        text.length * font_size * 0.5
      end

      def line_height(font_size:, line_spacing: 1.2)
        font_size * line_spacing
      end
    end.new(dummy: nil)
  end

  # A paragraph that has to split across pages is rebuilt from its
  # laid-out lines. The line break consumes the inter-word space, so
  # the rebuilt run list must re-insert separators — otherwise the
  # re-layout glues the boundary words together.
  describe '#split' do
    def flowable(text)
      described_class.new([Arrolio::InlineRun.new(text, style: style)],
                          style: style, measurer: measurer)
    end

    it 'keeps words separated across the split boundary' do
      head, tail = flowable('aa bb cc dd ee ff').split(60.0, 14.4, nil)
      expect(head).not_to be_nil
      expect(tail).not_to be_nil
      joined = tail.runs.map(&:text).join
      expect(joined).to eq('dd ee ff')
    end

    it 'does not insert a space after a hyphen break' do
      _, tail = flowable('aaaaaa-bbbbbb-cccccc').split(25.0, 14.4, nil)
      expect(tail.runs.map(&:text).join).to eq('bbbbbb-cccccc')
    end
  end
end
