# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TextFlowable do
  let(:style) { Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 11) }

  describe '#hanging_indent' do
    it 'defaults to zero' do
      tf = described_class.new(
        [Arrolio::InlineRun.new('hello world', style: style)],
        style: style
      )
      expect(tf.hanging_indent).to eq(0.0)
    end

    it 'carries the configured value through to the placed box' do
      tf = described_class.new(
        [Arrolio::InlineRun.new('[1] Citation text', style: style)],
        style: style,
        hanging_indent: 36.0
      )
      boxes, _consumed = tf.emit(72.0, 700.0, 451.0, nil)
      expect(boxes.length).to eq(1)
      expect(boxes.first.data[:hanging_indent]).to eq(36.0)
    end

    it 'reduces the effective width for layout calculations' do
      no_indent = described_class.new(
        [Arrolio::InlineRun.new('A' * 100, style: style)],
        style: style
      )
      with_indent = described_class.new(
        [Arrolio::InlineRun.new('A' * 100, style: style)],
        style: style,
        hanging_indent: 36.0
      )
      # Indenting wraps earlier → more lines.
      expect(with_indent.height(451.0)).to be >= no_indent.height(451.0)
    end
  end
end
