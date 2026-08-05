# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Table::AutoLayout do
  let(:header) { [Arrolio::Content::Table::Row.new([cell('Class A'), cell('Class B')])] }
  let(:body) { [Arrolio::Content::Table::Row.new([cell('100 000'), cell('10 000')])] }
  let(:table) { Arrolio::Content::Table.new(header: header, body: body) }

  def cell(text)
    Arrolio::Content::Table::Cell.new(
      [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new(text, style_id: :table_cell)]
      )]
    )
  end

  describe '#compute' do
    it 'returns widths summing to available_width' do
      layout = described_class.new(table, available_width: 400.0)
      widths = layout.compute
      expect(widths.sum).to be_within(0.01).of(400.0)
    end

    it 'returns one width per column' do
      layout = described_class.new(table, available_width: 400.0)
      expect(layout.compute.length).to eq(2)
    end

    it 'gives wider columns more space when content differs' do
      wide_header = [Arrolio::Content::Table::Row.new([cell('Very Long Header Text'), cell('X')])]
      wide_table = Arrolio::Content::Table.new(header: wide_header, body: [])
      layout = described_class.new(wide_table, available_width: 400.0)
      widths = layout.compute
      expect(widths[0]).to be > widths[1]
    end

    it 'respects minimum column width' do
      empty_table = Arrolio::Content::Table.new(
        header: [Arrolio::Content::Table::Row.new([cell(''), cell('')])],
        body: []
      )
      layout = described_class.new(empty_table, available_width: 100.0)
      widths = layout.compute
      expect(widths.all? { |w| w >= described_class::MIN_COLUMN_WIDTH }).to be(true)
    end

    it 'scales down when natural widths exceed available width' do
      wide_header = [
        Arrolio::Content::Table::Row.new([
          cell('Extremely Long Header Text That Cannot Fit'),
          cell('Another Very Long Header')
        ])
      ]
      wide_table = Arrolio::Content::Table.new(header: wide_header, body: [])
      layout = described_class.new(wide_table, available_width: 100.0)
      widths = layout.compute
      expect(widths.sum).to be_within(1.0).of(100.0)
    end

    it 'distributes colspan cell width across spanned slots' do
      colspan_cell = Arrolio::Content::Table::Cell.new(
        [Arrolio::Content::Paragraph.new(
          [Arrolio::Content::InlineRun.new('Wide Header', style_id: :table_cell)]
        )],
        colspan: 4
      )
      header = [Arrolio::Content::Table::Row.new([colspan_cell])]
      body = [
        Arrolio::Content::Table::Row.new([
          cell('A'), cell('B'), cell('C'), cell('D')
        ])
      ]
      colspan_table = Arrolio::Content::Table.new(header: header, body: body)
      layout = described_class.new(colspan_table, available_width: 400.0)
      widths = layout.compute
      expect(widths.length).to eq(4)
      expect(widths.all? { |w| w >= described_class::MIN_COLUMN_WIDTH }).to be(true)
    end
  end
end
