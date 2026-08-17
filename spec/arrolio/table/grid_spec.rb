# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Table::Grid do
  def cell(text, colspan: 1, rowspan: 1)
    Arrolio::Content::Table::Cell.new(
      [Arrolio::Content::Paragraph.new(
        [Arrolio::Content::InlineRun.new(text, style_id: :table_cell)]
      )],
      colspan: colspan, rowspan: rowspan
    )
  end

  def table(header_rows, body_rows)
    Arrolio::Content::Table.new(
      header: header_rows.map { |cells| Arrolio::Content::Table::Row.new(cells) },
      body: body_rows.map { |cells| Arrolio::Content::Table::Row.new(cells) }
    )
  end

  it 'places plain cells in document order' do
    grid = described_class.build(table([[cell('a'), cell('b')]], [[cell('c'), cell('d')]]))
    expect(grid.column_count).to eq(2)
    expect(grid.placements.map(&:column_index)).to eq([0, 1, 0, 1])
    expect(grid.placements.map(&:row_index)).to eq([0, 0, 1, 1])
  end

  it 'shifts later cells past a colspan' do
    grid = described_class.build(table(
                                   [[cell('wide', colspan: 2), cell('tail')]],
                                   [[cell('a'), cell('b'), cell('c')]]
                                 ))
    expect(grid.column_count).to eq(3)
    expect(grid.placements.first.column_index).to eq(0)
    expect(grid.placements[1].column_index).to eq(2)
  end

  # The Table 5 shape: a rowspan=9 cell in column 3; every following
  # row has one fewer cell and must skip the covered slot.
  it 'skips slots covered by a rowspan' do
    rows = [[cell('r1c1'), cell('r1c2'), cell('r1c3', rowspan: 2), cell('r1c4')],
            [cell('r2c1'), cell('r2c2'), cell('r2c4')]]
    grid = described_class.build(table([], rows))
    expect(grid.column_count).to eq(4)
    row2 = grid.placements_starting_in(1)
    expect(row2.map(&:column_index)).to eq([0, 1, 3])
    expect(row2.map { |p| p.cell.text }).to eq(['r2c1', 'r2c2', 'r2c4'])
  end

  it 'reports rowspan-welded rows as one atomic group' do
    rows = [[cell('a'), cell('span', rowspan: 3), cell('b')],
            [cell('c'), cell('d')],
            [cell('e'), cell('f')],
            [cell('g'), cell('h')]]
    grid = described_class.build(table([], rows))
    expect(grid.atomic_row_groups).to eq([[0, 1, 2], [3]])
  end

  it 'returns singleton groups when no row spans exist' do
    grid = described_class.build(table([], [[cell('a')], [cell('b')]]))
    expect(grid.atomic_row_groups).to eq([[0], [1]])
  end
end
