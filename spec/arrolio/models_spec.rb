# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Content::IndexEntry do
  it 'stores term and page numbers' do
    entry = described_class.new(term: 'load cell', page_numbers: [3, 7, 12])
    expect(entry.term).to eq('load cell')
    expect(entry.page_numbers).to eq([3, 7, 12])
  end

  it 'deduplicates and sorts page numbers' do
    entry = described_class.new(term: 'x', page_numbers: [5, 3, 3, 1])
    expect(entry.page_numbers).to eq([1, 3, 5])
  end

  it 'returns first letter for alphabetical grouping' do
    entry = described_class.new(term: 'Metrology', page_numbers: [1])
    expect(entry.first_letter).to eq('M')
  end

  it 'formats page numbers as comma-separated string' do
    entry = described_class.new(term: 'x', page_numbers: [1, 3, 5])
    expect(entry.page_numbers_str).to eq('1, 3, 5')
  end

  it 'is frozen' do
    expect(described_class.new(term: 'x', page_numbers: [])).to be_frozen
  end
end

RSpec.describe Arrolio::ColumnSet do
  let(:cs) { described_class.new(column_count: 3, gap: 10, total_width: 400, total_height: 700) }

  it 'computes column width excluding gaps' do
    expect(cs.column_width).to be_within(0.01).of(126.67)
  end

  it 'computes column x positions' do
    expect(cs.column_x(0)).to eq(0.0)
    expect(cs.column_x(1)).to be_within(0.01).of(136.67)
  end

  it 'iterates columns' do
    columns = cs.each_column.to_a
    expect(columns.length).to eq(3)
  end

  it 'is single_column when count <= 1' do
    single = described_class.new(column_count: 1, gap: 0, total_width: 400, total_height: 700)
    expect(single).to be_single_column
  end

  it 'is frozen' do
    expect(cs).to be_frozen
  end
end

RSpec.describe Arrolio::WritingMode do
  it 'defaults to lr-tb' do
    expect(described_class.new.ltr?).to be(true)
  end

  it 'detects vertical mode' do
    wm = described_class.new(described_class::TB_RL)
    expect(wm).to be_vertical
  end

  it 'detects RTL mode' do
    wm = described_class.new(described_class::RL_TB)
    expect(wm).to be_rtl
  end

  it 'returns inline direction vector' do
    lr = described_class.new(described_class::LR_TB)
    expect(lr.inline_direction).to eq([1, 0])
  end

  it 'parses string representations' do
    expect(described_class.parse('rl-tb')).to be_rtl
    expect(described_class.parse('tb-rl')).to be_vertical
  end

  it 'is frozen' do
    expect(described_class.new).to be_frozen
  end
end

RSpec.describe Arrolio::Content::FormField do
  it 'stores type, name, value, geometry' do
    field = described_class.new(
      type: :text, name: 'username', value: 'default',
      page_number: 1, x: 100, y: 200, width: 200, height: 20
    )
    expect(field.type).to eq(:text)
    expect(field.name).to eq('username')
    expect(field.text?).to be(true)
  end

  it 'detects checkbox type' do
    field = described_class.new(
      type: :checkbox, name: 'agree', page_number: 1,
      x: 0, y: 0, width: 15, height: 15
    )
    expect(field.checkbox?).to be(true)
  end

  it 'is frozen' do
    expect(described_class.new(
      type: :text, name: 'x', page_number: 1,
      x: 0, y: 0, width: 10, height: 10
    )).to be_frozen
  end
end

RSpec.describe Arrolio::Renderer::SignatureConfig do
  it 'stores keystore + cert level' do
    config = described_class.new(
      keystore_path: '/path/to/keystore.p12',
      keystore_password: 'secret',
      cert_level: :form_fill
    )
    expect(config.keystore_path).to eq('/path/to/keystore.p12')
    expect(config.cert_level_code).to eq(2)
  end

  it 'validates presence of keystore + password' do
    valid = described_class.new(keystore_path: '/x.p12', keystore_password: 'pw')
    invalid = described_class.new(keystore_path: '', keystore_password: '')
    expect(valid).to be_valid
    expect(invalid).not_to be_valid
  end

  it 'is frozen' do
    expect(described_class.new(keystore_path: '/x', keystore_password: 'y')).to be_frozen
  end
end
