# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flowables::TocLineFlowable do
  let(:style) do
    Arrolio::Style::Definition.new(font_name: 'Times-Roman', font_size: 11)
  end

  describe '#height' do
    it 'returns the line height of the resolved font' do
      tf = described_class.new('Foreword', 4, level: 1, style: style)
      expect(tf.height(451)).to be_positive
    end
  end

  describe '#emit' do
    it 'emits separate boxes for title, leader, and page number' do
      tf = described_class.new('Foreword', 4, level: 1, style: style)
      boxes, consumed = tf.emit(0, 700, 451, nil)
      expect(boxes.length).to be >= 2
      expect(consumed).to be_positive
    end

    it 'places the page number at the right edge of the line' do
      tf = described_class.new('Scope', 6, level: 1, style: style)
      boxes, = tf.emit(0, 700, 451, nil)
      # Find the right-most box (the page-number box)
      right_box = boxes.max_by(&:x)
      expect(right_box.x + right_box.width).to be_within(2.0).of(451)
    end

    it 'omits the leader box when there is no gap (long title)' do
      long_title = 'A very long section title that takes up most of the line width'
      tf = described_class.new(long_title, 99, level: 1, style: style)
      boxes, = tf.emit(0, 700, 200, nil)
      expect(boxes.length).to be >= 1
    end
  end

  describe 'shape and accessors' do
    it 'exposes title, page_number, level' do
      tf = described_class.new('Scope', 6, level: 2, style: style)
      expect(tf.title).to eq('Scope')
      expect(tf.page_number).to eq(6)
      expect(tf.level).to eq(2)
    end
  end
end
