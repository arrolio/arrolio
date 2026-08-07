# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::Table::Row do
  describe '#min_height' do
    it 'defaults to zero' do
      row = described_class.new([])
      expect(row.min_height).to eq(0.0)
    end

    it 'carries the configured value' do
      row = described_class.new([], min_height: 23.6)
      expect(row.min_height).to eq(23.6)
    end
  end

  describe 'equality' do
    it 'compares min_height' do
      row1 = described_class.new(['a'], min_height: 10.0)
      row2 = described_class.new(['a'], min_height: 10.0)
      row3 = described_class.new(['a'], min_height: 20.0)
      expect(row1).to eq(row2)
      expect(row1).not_to eq(row3)
    end
  end
end

RSpec.describe Arrolio::Flowables::TableFlowable do
  let(:cell) do
    Arrolio::Content::Table::Cell.new(
      [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new('x', style_id: :table_cell)]
      )]
    )
  end

  describe '#continued' do
    it 'defaults to false' do
      table = Arrolio::Content::Table.new(
        header: [[cell]],
        body: [[cell]]
      )
      tf = described_class.new(table)
      expect(tf.continued).to be(false)
    end

    it 'accepts continued: true' do
      table = Arrolio::Content::Table.new(
        header: [[cell]],
        body: [[cell]]
      )
      tf = described_class.new(table, continued: true, caption_text: 'Table 1')
      expect(tf.continued).to be(true)
      expect(tf.caption_text).to eq('Table 1')
    end
  end

  describe '#do_split' do
    it 'propagates continued: true to the tail' do
      rows = Array.new(20) { Arrolio::Content::Table::Row.new([cell]) }
      table = Arrolio::Content::Table.new(
        header: [Arrolio::Content::Table::Row.new([cell])],
        body: rows
      )
      tf = described_class.new(table, caption_text: 'Table 1')
      head, tail = tf.do_split(400, 50)
      expect(head).not_to be_nil
      expect(tail).not_to be_nil
      expect(tail.continued).to be(true)
      expect(tail.caption_text).to eq('Table 1')
    end
  end

  describe 'row min_height' do
    it 'respects row min_height over natural height' do
      short_row = Arrolio::Content::Table::Row.new(
        [Arrolio::Content::Table::Cell.new(
          [Arrolio::Content::Paragraph.new(
            [Arrolio::Content::InlineRun.new('x', style_id: :table_cell)]
          )]
        )],
        min_height: 100.0
      )
      table = Arrolio::Content::Table.new(header: [], body: [short_row])
      tf = described_class.new(table)
      total = tf.height(400)
      expect(total).to be >= 100.0
    end
  end
end
